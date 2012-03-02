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
import flash.geom.Vector3D;
import flash.geom.Rectangle;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.media.Camera;
import flash.media.Video;
import jp.maaash.objectdetection.ObjectDetector;
import jp.maaash.objectdetection.ObjectDetectorOptions;
import jp.maaash.objectdetection.ObjectDetectorEvent;
import com.bit101.components.PushButton;
import com.bit101.components.CheckBox;
import com.bit101.components.HUISlider;
import com.bit101.components.VBox;
import com.bit101.components.HBox;
import com.bit101.components.Label;
import com.bit101.components.Style;
import away3d.containers.Scene3D;
import away3d.containers.View3D;
import away3d.cameras.Camera3D;
import away3d.cameras.lenses.FreeMatrixLens;
import away3d.entities.Mesh;
import away3d.primitives.CubeGeometry;
import away3d.primitives.PlaneGeometry;
import away3d.materials.ColorMaterial;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.lights.DirectionalLight;
import away3d.lights.PointLight;
import org.casalib.util.ColorUtil;

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
	
	var frame:Int;
	
	var camera:Camera;
	var video:Video;
	var faceRects:Sprite;
	var videoHolder:Sprite;
	var flipCamMat:Matrix;
	
	var startBtn:PushButton;
	var screenWidthSlider:HUISlider;
	var flipCamBtn:CheckBox;
	var headSizeSlider:HUISlider;
	var headSizeALabel:Label;
	var headSizeABtn:PushButton;
	var headSizeBLabel:Label;
	var headSizeBBtn:PushButton;
	
	var scene3d:Scene3D;
	var view3d:View3D;
	var camera3d:Camera3D;
	var lens:FreeMatrixLens;
	var lightpicker:StaticLightPicker;
	var cube:Mesh;
	
	var detector:ObjectDetector;
	var bmpTarget:Bitmap;
	var isDetecting:Bool;
	
	var bm:BlockMatching;
	
	var screenWidth:Float;
	var headSize:Float;
	var headSizeA:Float;
	var headSizeB:Float;
	var headPos:Rectangle;
	var headPos3d:Vector3D;
	
    function new():Void {
    	super();
    	
    	addEventListener(Event.ADDED_TO_STAGE, init);
    }
    
    function onResize(evt:Event = null):Void {
    	if (stage.displayState != StageDisplayState.FULL_SCREEN) {
    		startBtn.setVisible(true);
    	}
    	
    	view3d.width = stage.stageWidth;
    	view3d.height = stage.stageHeight;
    	
    	startBtn.x = (stage.stageWidth - startBtn.getWidth()) * 0.5;
    	startBtn.y = (stage.stageHeight - startBtn.getHeight()) * 0.5;
    }
    
    function setHeadSizeA(evt:Event = null):Void {
    	if (!headSizeABtn.enabled) return;
    	
    	headSizeA = (headPos.width + headPos.height) * 0.5;
    	headSizeALabel.setText(HS_A_TEXT + headSizeA.int() + "px");
    }
    
    function setHeadSizeB(evt:Event = null):Void {
    	if (!headSizeBBtn.enabled) return;
    	
    	headSizeB = (headPos.width + headPos.height) * 0.5;
    	headSizeBLabel.setText(HS_B_TEXT + headSizeB.int() + "px");
    }
    
    function setSceenWidth(evt:Event = null):Void {
    	screenWidth = screenWidthSlider.value;
    }
    
    function setHeadSize(evt:Event = null):Void {
    	headSize = headSizeSlider.value;
    }
    
    function init(event:Event):Void {
    	removeEventListener(Event.ADDED_TO_STAGE, init);
    	
    	frame = 0;
    	
    	//init 3d
		
		view3d = new View3D();
		scene3d = view3d.scene;
		
		camera3d = view3d.camera;
		camera3d.moveTo(0, 0, 0);
		lens = new FreeMatrixLens();
		camera3d.lens = lens;
		
		var light = new DirectionalLight();
		scene3d.addChild(light);
		var plight = new PointLight();
		plight.moveTo(-2, 2, 10);
		scene3d.addChild(plight);
		
		lightpicker = new StaticLightPicker([light, plight]);
		
		view3d.antiAlias = 4;
		
		headPos3d = new Vector3D();
		headSizeA = 102;
		headSizeB = 71;
		
		var geom = new CubeGeometry(0.002, 0.002, 0.1);
		var m, material;
		for (k in 0...10) {
			material = new ColorMaterial(ColorUtil.getColor(0, k.map(0, 10, 255, 0).int(), 255), Math.pow(k.map(0, 10, 1, 0), 0.8));
			for (i in 0...6)
			for (j in 0...6) 
			{
				m = new Mesh(geom, material);
				m.moveTo(i.map(0, 5, -1, 1), j.map(0, 5, -1, 1), k.map(0, 10, -0.05, -2));
				scene3d.addChild(m);
			}
		}
		
		material = new ColorMaterial(0xFF0000);
		material.lightPicker = lightpicker;
		cube = new Mesh(new CubeGeometry(0.1, 0.1, -0.1), material);
		cube.moveTo(-0.1, 0.13, 0.5);
		cube.rotationX = 45;
		cube.rotationY = 45;
		cube.rotationZ = 45;
		scene3d.addChild(cube);
		
		material = new ColorMaterial(0x000000, 0.5);
		var plane = new Mesh(new CubeGeometry(4, 4, 0.001), material);
		scene3d.addChild(plane);
		
		addChild(view3d);
    	
    	
    	//init webcam
    	
    	videoHolder = new Sprite();
		videoHolder.scaleX = videoHolder.scaleY = 0.5;
		videoHolder.x = 5;
		videoHolder.y = 5;
		addChild(videoHolder);
		
		video = new Video(CAM_W, CAM_H);
		
		bmpTarget = new Bitmap(new BitmapData(CAM_W, CAM_H, false));
		videoHolder.addChild(bmpTarget);
		
		faceRects = new Sprite();
		videoHolder.addChild(faceRects);
		
		flipCamMat = new Matrix();
		flipCamMat.scale(-1, 1);
		flipCamMat.translate(CAM_W, 0);
		
		//init face dectector
		
		detector = new ObjectDetector();
		detector.options = getDetectorOptions();
		detector.loadHaarCascadesFromXml(Xml.parse(nme.Assets.getText("assets/haarcascade_frontalface_alt.xml")));
		detector.addEventListener(ObjectDetectorEvent.DETECTION_COMPLETE, onDetectionComplete);
		
   		
   		//init UI
   		
    	startBtn = new PushButton(this, 0, 0, "start (fullscreen)");
    	startBtn.addEventListener(MouseEvent.CLICK, start);
    	
   		var guiBox = new MyVBox(this, 5, 10 + videoHolder.y + CAM_H * videoHolder.scaleY);
   		
   		flipCamBtn = new CheckBox(guiBox, 0, 0, "flip camera");
   		flipCamBtn.setSelected(true);
    	
    	screenWidthSlider = new HUISlider(guiBox, 0, 0, "screen width", setSceenWidth);
    	screenWidthSlider.setMinimum(1);
    	screenWidthSlider.setMaximum(5);
    	screenWidthSlider.setValue(1.5);
    	setSceenWidth();
    	
    	headSizeSlider = new HUISlider(guiBox, 0, 0, "head size", setHeadSize);
    	headSizeSlider.setMinimum(0.1);
    	headSizeSlider.setMaximum(2);
    	headSizeSlider.setValue(0.8);
    	setHeadSize();
    	
    	var hsA = new HBox(guiBox);
    	headSizeALabel = new Label(hsA, 0, 0, HS_A_TEXT);
    	headSizeABtn = new PushButton(hsA, 0, 0, "get", setHeadSizeA);
    	headSizeABtn.setSize(30, 18);
    	headSizeABtn.setEnabled(false);
    	
    	var hsB = new HBox(guiBox);
    	headSizeBLabel = new Label(hsB, 0, 0, HS_B_TEXT);
    	headSizeBBtn = new PushButton(hsB, 0, 0, "get", setHeadSizeB);
    	headSizeBBtn.setSize(30, 18);
    	headSizeBBtn.setEnabled(false);
    	
		
    	onResize();
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
    	
    	var screenHeight = screenWidth*stage.stageHeight/stage.stageWidth;
    	
    	//screen's bottom left corner
    	var pa = new Vector3D(-screenWidth*0.5, -screenHeight*0.5, 0);
    	
    	//screen's bottom right corner
    	var pb = new Vector3D(screenWidth*0.5, -screenHeight*0.5, 0);
    	
    	//screen's top left corner
    	var pc = new Vector3D(-screenWidth*0.5, screenHeight*0.5, 0);
    	
    	//head position
    	var pe = if (headPos == null || Math.isNaN(headSizeA) || Math.isNaN(headSizeB)) {
    		new Vector3D(0, 0, 10);
    	} else {
    		var headSizeCur = (headPos.width + headPos.height) * 0.5;
    		headPos3d.z = (headSizeA*HS_A_DIST + headSizeB*HS_B_DIST)*0.5 / headSizeCur;
    		var headPosCenter = new Point(headPos.x + headPos.width * 0.5 - CAM_W * 0.5, headPos.y + headPos.height * 0.5 - CAM_H * 0.5);
    		headPos3d.x = headPosCenter.x * headSize/headSizeCur;
    		headPos3d.y = -headPosCenter.y * headSize/headSizeCur;
    		headPos3d;
    	}
    	
    	//near clipping plane
    	var n = 0.01;
    	
    	//far clipping plane
    	var f = 100;
    	
    	
    	lens.matrix = generalized_perspective_projection(pa, pb, pc, pe, n, f);
    	
    	cube.roll(1);
    	cube.z = Math.sin(frame/(24*2)) * 0.5;
    	
    	view3d.render();
    	
    	++frame;
    }
    
    function onDetectionComplete(e:ObjectDetectorEvent):Void {
		if ( e.rects != null && e.rects.length > 0) {
			if (headPos == null) {
				headPos = e.rects[0];
				
    			headSizeABtn.setEnabled(true);
    			headSizeBBtn.setEnabled(true);
			}
			
			//choose the result that is closest to current headPos
			var headPosCenter = new Point(headPos.x + headPos.width * 0.5, headPos.y + headPos.height * 0.5);
			var targetPos = e.rects.fold(function(r:Rectangle, min:Array<Dynamic>){
				var d = Point.distance(new Point(r.x + r.width * 0.5, r.y + r.height * 0.5), headPosCenter);
				return d < min[1] ? [r, d] : min;
			}, [null, Math.POSITIVE_INFINITY])[0];
			
			//smoothen the position
			headPos.topLeft = Point.interpolate(headPos.topLeft, targetPos.topLeft, 0.7);
			headPos.bottomRight = Point.interpolate(headPos.bottomRight, targetPos.bottomRight, 0.7);
			
			//draw all detection result
			var g = faceRects.graphics;
			g.clear();
			g.lineStyle(1, 0x000000);
			for (r in e.rects) {
				g.drawRect(r.x, r.y, r.width, r.height);
			}
			
			//draw headPos
			g.lineStyle(2, 0xFF0000);
			g.drawRect(headPos.x, headPos.y, headPos.width, headPos.height);
		}
		isDetecting = false;
	}
    
    function startDetection():Void {
    	isDetecting = true;
    	
    	if (flipCamBtn.getSelected())
			bmpTarget.bitmapData.draw(video, flipCamMat);
		else
			bmpTarget.bitmapData.draw(video);
		
		detector.detect(bmpTarget);
	}
    
    static function getDetectorOptions():ObjectDetectorOptions {
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
	
	/*
	 * Generalized Perspective Projection
	 * Robert Kooima, August 2008, revised June 2009
	 */
	static public function generalized_perspective_projection(pa:Vector3D, pb:Vector3D, pc:Vector3D, pe:Vector3D, n:Float, f:Float):Matrix3D {
    
	    //Compute an orthonormal basis for the screen.
	    var vr = pb.subtract(pa);
	    vr.normalize();
	    var vu = pc.subtract(pa);
	    vu.normalize();
	    var vn = vr.crossProduct(vu);
	    vn.normalize();
	    
	    //Compute the screen corner vectors.
	    var va = pa.subtract(pe);
	    var vb = pb.subtract(pe);
	    var vc = pc.subtract(pe);
	    
	    //Find the distance from the eye to screen plane.
	    var d = -(va.dotProduct(vn));
	    
	    //Find the extent of the perpendicular projection.
	    var m = n / d;
	    var l = vr.dotProduct(va) * m;
	    var r = vr.dotProduct(vb) * m;
	    var b = vu.dotProduct(va) * m;
	    var t = vu.dotProduct(vc) * m;
	    
	    //Load the perpendicular projection.
	    //glFrustum(l, r, b, t, n, f);
	    var mat = new Matrix3D(flash.Vector.ofArray([2.0*n/(r-l), 0, (r+l)/(r-l), 0, 0, 2.0*n/(t-b), (t+b)/(t-b), 0, 0, 0, (f+n)/(n-f), 2.0*f*n/(n-f), 0, 0, -1, 0]));
	    
	    //Rotate the projection to be non-perpendicular.
	    mat.append(new Matrix3D(flash.Vector.ofArray([vr.x, vr.y, vr.z, 0, vu.x, vu.y, vu.z, 0, vn.x, vn.y, vn.z, 0, 0, 0, 0, 1])));
	    
	    //Move the apex of the frustum to the origin.
	    mat.append(new Matrix3D(flash.Vector.ofArray([1, 0, 0, -pe.x, 0, 1, 0, -pe.y, 0, 0, 1, -pe.z, 0, 0, 0, 1])));
	    
	    
	    mat.transpose();
	    return mat;
    }
}