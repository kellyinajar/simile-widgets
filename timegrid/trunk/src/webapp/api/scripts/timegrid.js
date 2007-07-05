/******************************************************************************
 * Timegrid
 *****************************************************************************/

Timegrid.create = function(node, eventSource, layoutName, layoutParams) {
    return new Timegrid._Impl(node, eventSource, layoutName, layoutParams);
};

Timegrid.createFromDOM = function(elmt) {
    var config = Timegrid.getConfigFromDOM(elmt);
    var eventSource = new Timegrid.DefaultEventSource();
    var layoutNames = config.views.split(",");
    var tg = Timegrid.create(elmt, eventSource, layoutNames, config);
    if (config.src) {
        tg.loadXML(config.src, function(xml, url) {
            eventSource.loadXML(xml, url);
        });
    }
    return tg;
};

Timegrid.getConfigFromDOM = function(elmt) {
    var config = $(elmt).attrs('tg');
    config.scrollwidth = $.scrollWidth();
    return config;
};

Timegrid.loadXML = function(url, f) {
    var fError = function(statusText, status, xmlhttp) {
        alert("Failed to load data XML from " + url + "\n" + statusText);
    };
    var fDone = function(xmlhttp) {
        var xml = xmlhttp.responseXML;
        if (!xml.documentElement && xmlhttp.responseStream) {
            xml.load(xmlhttp.responseStream);
        }
        f(xml, url);
    };
    SimileAjax.XmlHttp.get(url, fError, fDone);
};

Timegrid.loadJSON = function(url, f) {
    var fError = function(statusText, status, xmlhttp) {
        alert("Failed to load JSON data from " + url + "\n" + statusText);
    };
    var fDone = function(xmlhttp) {
        f(eval('(' + xmlhttp.responseText + ')'), url);
    };
    SimileAjax.XmlHttp.get(url, fError, fDone);
};

Timegrid._Impl = function(node, eventSource, layoutNames, layoutParams) {
    var tg = this;
    this._container = node;
    this._eventSource = eventSource;
    this._layoutNames = layoutNames;
    this._layoutParams = layoutParams;

    if (this._eventSource) {
        this._eventListener = {
            onAddMany: function() { tg._onAddMany(); },
            onClear:   function() { tg._onClear(); }
        }
        this._eventSource.addListener(this._eventListener);
    }
    this._construct();
};

Timegrid._Impl.prototype.loadXML = function(url, f) {
    var tg = this;

    var fError = function(statusText, status, xmlhttp) {
        alert("Failed to load data xml from " + url + "\n" + statusText);
        tg.hideLoadingMessage();
    };
    var fDone = function(xmlhttp) {
        try {
            var xml = xmlhttp.responseXML;
            if (!xml.documentElement && xmlhttp.responseStream) {
                xml.load(xmlhttp.responseStream);
            }
            f(xml, url);
        } finally {
            tg.hideLoadingMessage();
        }
    };
    this.showLoadingMessage();
    window.setTimeout(function() {
        SimileAjax.XmlHttp.get(url, fError, fDone);
    }, 0);
};

Timegrid._Impl.prototype._construct = function() {
    var self = this;
    this._layouts = $.map(this._layoutNames, function(s) {
        return Timegrid.LayoutFactory.createLayout(s, self._eventSource,
                                                      self._layoutParams);
    });
    this._panel = new Timegrid.Controls.Panel(this._layouts);
    var container = this._container;
    var doc = container.ownerDocument;

    while (container.firstChild) {
        container.removeChild(container.firstChild);
    }
    $(container).addClass('timegrid-default');

    var message = SimileAjax.Graphics.createMessageBubble(doc);
    message.containerDiv.className = "timegrid-message-container";
    container.appendChild(message.containerDiv);

    message.contentDiv.className = "timegrid-message";
    message.contentDiv.innerHTML = "<img src='" + Timegrid.urlPrefix
        + "images/progress-running.gif' /> Loading...";

    this.showLoadingMessage = function() { $(message.containerDiv).show(); };
    this.hideLoadingMessage = function() { $(message.containerDiv).hide(); };

    this._panel.render(container);
};

Timegrid._Impl.prototype._onAddMany = function() {
    this._construct();
};

Timegrid._Impl.prototype._onClear = function() {
    this._construct();
};

