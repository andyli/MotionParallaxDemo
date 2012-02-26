package;

import flash.Lib;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.media.Camera;
import flash.media.Video;
import jp.maaash.objectdetection.ObjectDetectorOptions;
import jp.maaash.objectdetection.ObjectDetectorEvent;

using Lambda;
using org.casalib.util.ConversionUtil;
using org.casalib.util.NumberUtil;

class MotionParallaxDemo extends Sprite {
	var camera:Camera;
	var video:Video;
	var faceRects:Sprite;
	var videoHolder:Sprite;
	
	var detector:MyObjectDetector;
	var bmpTarget:Bitmap;
	
	var headPos:Rectangle;
	
	var isDetecting:Bool;
	
    function new():Void {
    	super();
    	
    	addEventListener(Event.ADDED_TO_STAGE, init);
    }
    
    function init(event:Event):Void {
    	removeEventListener(Event.ADDED_TO_STAGE, init);
    	
		videoHolder = new Sprite();
		videoHolder.scaleX = videoHolder.scaleY = 0.5;
		addChild(videoHolder);
    	
    	camera = Camera.getCamera();
    	camera.setMode(320, 240, 24);
		video = new Video(camera.width, camera.height);
		video.attachCamera(camera);
		videoHolder.addChild(video);
		
		faceRects = new Sprite();
		videoHolder.addChild(faceRects);
		
		detector = new MyObjectDetector();
		detector.options = getDetectorOptions();
		detector.loadHaarCascadesFromXml(haxe.Resource.getString("haarcascade"));
		detector.addEventListener(ObjectDetectorEvent.DETECTION_COMPLETE, onDetectionComplete);
		
		bmpTarget = new Bitmap(new BitmapData( Std.int(video.width), Std.int(video.height), false));

		addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }
    
    function onEnterFrame(evt:Event):Void {
    	if (!isDetecting) {
    		startDetection();
    	}
    }
    
    function onDetectionComplete(e:ObjectDetectorEvent):Void {
		if ( e.rects != null && e.rects.length > 0) {
			if (headPos == null) {
				headPos = e.rects[0];
			}
			
			var headPosCenter = new Point(headPos.x + headPos.width * 0.5, headPos.y + headPos.height * 0.5);
			var targetPos = e.rects.fold(function(r:Rectangle, min:Array<Dynamic>){
				var d = Point.distance(new Point(r.x + r.width * 0.5, r.y + r.height * 0.5), headPosCenter);
				return d < min[1] ? [r, d] : min;
			}, [null, Math.POSITIVE_INFINITY])[0];
			headPos.topLeft = Point.interpolate(headPos.topLeft, targetPos.topLeft, 0.5);
			headPos.bottomRight = Point.interpolate(headPos.bottomRight, targetPos.bottomRight, 0.5);
			
			var g = faceRects.graphics;
			g.clear();
			g.lineStyle(1, 0x000000);
			for (r in e.rects) {
				g.drawRect(r.x, r.y, r.width, r.height);
			}
			
			g.lineStyle(2, 0xFF0000);
			g.drawRect(headPos.x, headPos.y, headPos.width, headPos.height);
		}
		isDetecting = false;
	}
    
    function startDetection():Void {
    	isDetecting = true;
		bmpTarget.bitmapData.draw(video);
		detector.detect(bmpTarget);
	}
    
    function getDetectorOptions():ObjectDetectorOptions {
		var options = new ObjectDetectorOptions();
		options.minSize   = 50;
		options.startx    = ObjectDetectorOptions.INVALID_POS;
		options.starty    = ObjectDetectorOptions.INVALID_POS;
		options.endx      = ObjectDetectorOptions.INVALID_POS;
		options.endy      = ObjectDetectorOptions.INVALID_POS;
		return options;
	}
	
	static function main():Void {
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		Lib.current.stage.align = StageAlign.TOP_LEFT;
		Lib.current.addChild(new MotionParallaxDemo());
	}
}