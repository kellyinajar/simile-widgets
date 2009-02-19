package org.simileWidgets.runway {
    import flash.display.*;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.PerspectiveProjection;
    
    public class RunwayBase extends Sprite {
        protected var _boundingWidth:Number;
        protected var _boundingHeight:Number;
        
        protected var _theme:Theme;
        protected var _geometry:Geometry;
        protected var _settingsDirty:Boolean = false;
        protected var _backgroundDirty:Boolean = false;
        
        protected var _mask:Sprite;
        protected var _platformView:Sprite;
        protected var _platform:Sprite;
        
        protected var _reflectionMask:BitmapData;
        
        public function RunwayBase(boundingWidth:Number, boundingHeight:Number, theme:Theme, geometry:Geometry) {
            _boundingWidth = boundingWidth;
            _boundingHeight = boundingHeight;
            
            _theme = theme;
            _geometry = geometry;
            _geometry.recalculate(boundingWidth, boundingHeight);
            
            _platformView = new Sprite();
            _platformView.transform.perspectiveProjection = new PerspectiveProjection();
            addChild(_platformView);
            
            _platform = new Sprite();
            _platformView.addChild(_platform);
            
            _setPerspective();
            _redrawBackground();
        }
        
        public function get boundingWidth():Number {
            return _boundingWidth;
        }
        public function set boundingWidth(newBoundingWidth:Number):void {
            newBoundingWidth = Math.round(Math.max(100, newBoundingWidth));
            if (_boundingWidth != newBoundingWidth) {
                _boundingWidth = newBoundingWidth;
                _backgroundDirty = true;
            }
        }
        
        public function get boundingHeight():Number {
            return _boundingHeight;
        }
        public function set boundingHeight(newBoundingHeight:Number):void {
            newBoundingHeight = Math.round(Math.max(100, newBoundingHeight));
            if (_boundingHeight != newBoundingHeight) {
                _boundingHeight = newBoundingHeight;
                _settingsDirty = true;
                _backgroundDirty = true;
            }
        }
        
        public function get theme():Theme {
            return _theme;
        }
        
        public function get geometry():Geometry {
            return _geometry;
        }
        
        public function forceLayout():void {
            _settingsDirty = true;
            _backgroundDirty = true;
        }
        
        public function get reflectionMask():BitmapData {
            if (_reflectionMask == null) {
                var size:Number = _geometry.maxSlideSizePixels;
                
                var gradientMatrix:Matrix = new Matrix();
                var gradientSprite:Sprite = new Sprite();
                
                gradientMatrix.createGradientBox(
                    size, 
                    size * _theme.reflectionExtent, 
                    Math.PI/2, 
                    0, 
                    size * (1.0 - _theme.reflectionExtent)
                );
                gradientSprite.graphics.beginGradientFill(
                    GradientType.LINEAR, 
                    [0xFFFFFF, 0xFFFFFF], 
                    [0, _theme.reflectivity], 
                    [32, 224], 
                    gradientMatrix
                );
                gradientSprite.graphics.drawRect(
                    0, 
                    size * (1.0 - _theme.reflectionExtent), 
                    size, 
                    size * _theme.reflectionExtent
                );
                gradientSprite.graphics.endFill();
                
                _reflectionMask = new BitmapData(size, size, true, 0x00000000);
                _reflectionMask.draw(gradientSprite, new Matrix());
            }
            return _reflectionMask;
        }
        
        protected function _ensureCleanSettings():Boolean {
            if (_settingsDirty || _geometry.dirty) {
                if (_reflectionMask != null) {
                    _reflectionMask.dispose();
                    _reflectionMask = null;
                }
                
                _geometry.recalculate(boundingWidth, boundingHeight);
                
                _geometry.dirty = false;
                _settingsDirty = false;
                return true;
            }
            return false;
        }
        protected function _ensureCleanBackground():Boolean {
            if (_backgroundDirty || _theme.dirty) {
                _redrawBackground();
                
                _theme.dirty = false;
                _backgroundDirty = false;
                return true;
            }
            return false;
        }
        
        protected function _redrawBackground():void {
            _setPerspective();
            
            graphics.clear();
            
            var mtx:Matrix = new Matrix();
            mtx.createGradientBox(boundingWidth, boundingHeight, Math.PI / 2);
                
            if (_theme.backgroundGradient == "single") {
                graphics.beginGradientFill(
                    GradientType.LINEAR,
                    [ _theme.backgroundColorTop, _theme.backgroundColorBottom ], 
                    [ 1.0, 1.0 ],
                    [ 0x00, 0xFF ], 
                    mtx, 
                    SpreadMethod.PAD
                );
            } else if (_theme.backgroundGradient == "double") {
                graphics.beginGradientFill(
                    GradientType.LINEAR,
                    [ _theme.backgroundColorTop, _theme.backgroundColorMiddle, _theme.backgroundColorBottom ], 
                    [ 1.0, 1.0, 1.0 ],
                    [ 0x00, Math.round(_geometry.horizon * 0xFF), 0xFF ], 
                    mtx, 
                    SpreadMethod.PAD
                );
            } else {
                graphics.beginFill(_theme.backgroundColor, 1.0);
                graphics.lineStyle();
            }
            
            graphics.drawRect(0, 0, boundingWidth, boundingHeight);
            graphics.endFill();
        }
        
        protected function _setPerspective():void {
            _platformView.x = boundingWidth / 2;
            _platformView.y = 0;
            _platformView.transform.perspectiveProjection.projectionCenter = new Point(0, boundingHeight / 2);
            _platformView.transform.perspectiveProjection.fieldOfView = 45;
            
            _platformView.graphics.clear();
            _platformView.graphics.lineStyle(1, 0xFFFFFF);
            _platformView.graphics.moveTo(0, 0);
            _platformView.graphics.lineTo(0, boundingHeight);
            _platformView.graphics.moveTo(0, boundingHeight / 2);
            _platformView.graphics.lineTo(boundingWidth / 2, boundingHeight / 2);
            
            _platform.y = Math.round((boundingHeight - _geometry.slideSizePixels) / 3);
        }
    }
}
