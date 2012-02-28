package;

import flash.Lib;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.display.StageDisplayState;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.KeyboardEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.media.Camera;
import flash.media.Video;
import jp.maaash.objectdetection.ObjectDetectorOptions;
import jp.maaash.objectdetection.ObjectDetectorEvent;
import com.bit101.components.PushButton;
import com.bit101.components.HUISlider;
import com.bit101.components.VBox;
import com.bit101.components.HBox;
import com.bit101.components.Label;
import com.bit101.components.Style;

using Std;
using Lambda;
using org.casalib.util.ConversionUtil;
using org.casalib.util.NumberUtil;

class MotionParallaxDemo extends Sprite {
	inline static var CAM_W = 320;
	inline static var CAM_H = 240;
	
	inline static var HS_A_DIST = 2;
	inline static var HS_B_DIST = 3;
	
	inline static var HS_A_TEXT = "head size at distance "+HS_A_DIST+": ";
	inline static var HS_B_TEXT = "head size at distance "+HS_B_DIST+": ";
	
	var camera:Camera;
	var video:Video;
	var faceRects:Sprite;
	var videoHolder:Sprite;
	var startBtn:PushButton;
	var screenWidthSlider:HUISlider;
	var headSizeALabel:Label;
	var headSizeABtn:PushButton;
	var headSizeBLabel:Label;
	var headSizeBBtn:PushButton;
	
	var detector:MyObjectDetector;
	var bmpTarget:Bitmap;
	
	var screenWidth:Float;
	var headSizeA:Float;
	var headSizeB:Float;
	var headPos:Rectangle;
	
	var isDetecting:Bool;
	
    function new():Void {
    	super();
    	
    	addEventListener(Event.ADDED_TO_STAGE, init);
    }
    
    function onResize(evt:Event):Void {
    	if (stage.displayState != StageDisplayState.FULL_SCREEN) {
    		startBtn.setVisible(true);
    	}
    	
    	videoHolder.x = (stage.stageWidth - CAM_W * videoHolder.scaleX) * 0.5;
    	videoHolder.y = 0;
    }
    
    function setHeadSizeA(evt:Event):Void {
    	if (!headSizeABtn.enabled) return;
    	
    	headSizeA = (headPos.width + headPos.height) * 0.5;
    	headSizeALabel.setText(HS_A_TEXT + headSizeA.int());
    }
    
    function setHeadSizeB(evt:Event):Void {
    	if (!headSizeBBtn.enabled) return;
    	
    	headSizeB = (headPos.width + headPos.height) * 0.5;
    	headSizeBLabel.setText(HS_B_TEXT + headSizeB.int());
    }
    
    function init(event:Event):Void {
    	removeEventListener(Event.ADDED_TO_STAGE, init);
   		
   		var guiBox = new VBox(this, 0, 0);
   		
    	startBtn = new PushButton(this, 0, 0, "start (fullscreen)");
    	startBtn.x = (stage.stageWidth - startBtn.getWidth()) * 0.5;
    	startBtn.y = (stage.stageHeight - startBtn.getHeight()) * 0.5;
    	startBtn.addEventListener(MouseEvent.CLICK, start);
    	
    	screenWidthSlider = new HUISlider(guiBox, 0, 0, "screen width");
    	screenWidthSlider.setMinimum(1);
    	screenWidthSlider.setMaximum(5);
    	screenWidthSlider.setValue(1.5);
    	
    	var hsA = new HBox(guiBox);
    	headSizeALabel = new Label(hsA, 0, 0, HS_A_TEXT);
    	headSizeABtn = new PushButton(hsA, 0, 0, "set from camera", setHeadSizeA);
    	headSizeABtn.setSize(100, 18);
    	headSizeABtn.setEnabled(false);
    	
    	var hsB = new HBox(guiBox);
    	headSizeBLabel = new Label(hsB, 0, 0, HS_B_TEXT);
    	headSizeBBtn = new PushButton(hsB, 0, 0, "set from camera", setHeadSizeB);
    	headSizeBBtn.setSize(100, 18);
    	headSizeBBtn.setEnabled(false);
    	
    	
    	videoHolder = new Sprite();
		videoHolder.scaleX = videoHolder.scaleY = 0.5;
		addChild(videoHolder);
		
		video = new Video(CAM_W, CAM_H);
		videoHolder.addChild(video);
		
		faceRects = new Sprite();
		videoHolder.addChild(faceRects);
		
		
		detector = new MyObjectDetector();
		detector.options = getDetectorOptions();
		detector.loadHaarCascadesFromXml(haxe.Resource.getString("haarcascade"));
		detector.addEventListener(ObjectDetectorEvent.DETECTION_COMPLETE, onDetectionComplete);
		
		bmpTarget = new Bitmap(new BitmapData(CAM_W, CAM_H, false));
		
    	
    	stage.addEventListener(Event.RESIZE, onResize);
    }
    
    function start(evt:MouseEvent):Void {
    	startBtn.setVisible(false);
    	stage.displayState = StageDisplayState.FULL_SCREEN;
    	
    	camera = Camera.getCamera();
    	camera.setMode(CAM_W, CAM_H, 24);
		video.attachCamera(camera);
		
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
				
    			headSizeABtn.setEnabled(true);
    			headSizeBBtn.setEnabled(true);
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
	
	static public function main():Void {
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		Lib.current.stage.align = StageAlign.TOP_LEFT;
		Lib.current.addChild(new MotionParallaxDemo());
	}
}