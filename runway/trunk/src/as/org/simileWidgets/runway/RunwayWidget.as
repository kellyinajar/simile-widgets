package org.simileWidgets.runway {
    import flash.external.ExternalInterface;
    import flash.system.Security;
    import flash.display.Sprite;
    import flash.events.*;

    [SWF(frameRate="30")]
    public class RunwayWidget extends Sprite {
        private var _runway:Runway;
        
        public function RunwayWidget() {
            stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
            stage.align = flash.display.StageAlign.TOP_LEFT;
            stage.addEventListener(Event.RESIZE, resizeListener);
            
            _runway = new Runway(stage.stageWidth, stage.stageHeight);
            addChild(_runway);
            
            if (ExternalInterface.available) {
                Security.allowDomain('*'); // This allows Javascript from any web page to call us.
                setupCallbacks();
            } else {
                trace("External interface is not available for this container.");
            }
        }
        
        public function getFoo(a:Array):String {
            //new Foo();
            return a.join(";");
        }
        
        private function resizeListener(e:Event):void {
            _runway.boundingWidth = stage.stageWidth;
            _runway.boundingHeight = stage.stageHeight;
        }
        
        private function setupCallbacks():void {
            try {
                ExternalInterface.addCallback("setRecords", _runway.setRecords); 
            } catch (e:Error) {
                trace("Error adding callbacks");
            }
        }
    }
}
