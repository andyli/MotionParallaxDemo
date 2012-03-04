package;

import flash.Lib;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.GradientType;
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
import away3d.containers.ObjectContainer3D;
import away3d.primitives.CubeGeometry;
import away3d.materials.ColorMaterial;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.lights.DirectionalLight;
import away3d.lights.PointLight;
import org.casalib.util.ColorUtil;

using Std;
using Lambda;
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
	var faceRectsSp:Sprite;
	var trackRectSp:Sprite;
	var videoHolder:Sprite;
	var flipCamMat:Matrix;
	
	var startFullBtn:PushButton;
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
	var bgHolder:ObjectContainer3D;
	
	var detector:ObjectDetector;
	var bmpTargetPrev:Bitmap;
	var bmpTarget:Bitmap;
	
	var blockmatcher:BlockMatcher;
	
	var screenWidth:Float;
	var headSize:Float;
	var headSizeA:Float;
	var headSizeB:Float;
	var headRect:Rectangle;
	var headPos3d:Vector3D;
	
    function new():Void {
    	super();
    	
    	addEventListener(Event.ADDED_TO_STAGE, init);
    }
    
    function onResize(evt:Event = null):Void {
    	if (stage.displayState != StageDisplayState.FULL_SCREEN) {
	    	screenWidthSlider.setValue(0.6);
    	} else {
	    	screenWidthSlider.setValue(1.5);
    	}
    	setSceenWidth();
    	
    	view3d.width = stage.stageWidth;
    	view3d.height = stage.stageHeight;
    }
    
    function setHeadSizeA(evt:Event = null):Void {
    	if (!headSizeABtn.enabled) return;
    	
    	headSizeA = (headRect.width + headRect.height) * 0.5;
    	headSizeALabel.setText(HS_A_TEXT + headSizeA.int() + "px");
    }
    
    function setHeadSizeB(evt:Event = null):Void {
    	if (!headSizeBBtn.enabled) return;
    	
    	headSizeB = (headRect.width + headRect.height) * 0.5;
    	headSizeBLabel.setText(HS_B_TEXT + headSizeB.int() + "px");
    }
    
    function setSceenWidth(evt:Event = null):Void {
    	screenWidth = screenWidthSlider.value;
    	initBg();
    }
    
    function setHeadSize(evt:Event = null):Void {
    	headSize = headSizeSlider.value;
    }
    
    function initBg():Void {
    	for (i in 0...bgHolder.numChildren) {
			bgHolder.removeChild(bgHolder.getChildAt(0));
		}
		var geom = new CubeGeometry(0.002, 0.002, screenWidth*0.1);
		var m, material;
		for (k in 0...10) {
			material = new ColorMaterial(ColorUtil.getColor(0, k.map(0, 10, 255, 0).int(), 255), Math.pow(k.map(0, 10, 1, 0), 0.8));
			for (i in 0...6)
			for (j in 0...6) 
			{
				m = new Mesh(geom, material);
				m.moveTo(i.map(0, 5, -screenWidth*0.5, screenWidth*0.5), j.map(0, 5, -screenWidth*0.5, screenWidth*0.5), k.map(0, 10, -0.05, -screenWidth*1.5));
				bgHolder.addChild(m);
			}
		}
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
		headSizeA = 100;
		headSizeB = 70;
		
		bgHolder = new ObjectContainer3D();
		scene3d.addChild(bgHolder);
		initBg();
		
		var material = new ColorMaterial(0xFF0000);
		material.lightPicker = lightpicker;
		cube = new Mesh(new CubeGeometry(0.1, 0.1, -0.1), material);
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
		
		bmpTargetPrev = new Bitmap(new BitmapData(CAM_W, CAM_H, false));
		bmpTarget = new Bitmap(new BitmapData(CAM_W, CAM_H, false));
		videoHolder.addChild(bmpTarget);
		
		faceRectsSp = new Sprite();
		videoHolder.addChild(faceRectsSp);
		
		trackRectSp = new Sprite();
		videoHolder.addChild(trackRectSp);
		
		flipCamMat = new Matrix();
		flipCamMat.scale(-1, 1);
		flipCamMat.translate(CAM_W, 0);
		
		//init face dectector
		
		detector = new ObjectDetector();
		detector.options = getDetectorOptions();
		detector.loadHaarCascadesFromXml(Xml.parse(nme.Assets.getText("assets/haarcascade_frontalface_alt.xml")));
		
		//init blockmatcher
		
		blockmatcher = new BlockMatcher().init(40, 5, 40, 0.005);
		
   		
   		//init UI
    	
   		var guiBox = new MyVBox(this, 10, 10 + videoHolder.y + CAM_H * videoHolder.scaleY);
   		
   		flipCamBtn = new CheckBox(guiBox, 0, 0, "flip camera");
   		flipCamBtn.setSelected(true);
    	
    	screenWidthSlider = new HUISlider(guiBox, 0, 0, "screen width", setSceenWidth);
    	screenWidthSlider.setMinimum(0.5);
    	screenWidthSlider.setMaximum(5);
    	setSceenWidth();
    	
    	headSizeSlider = new HUISlider(guiBox, 0, 0, "head size", setHeadSize);
    	headSizeSlider.setMinimum(0.1);
    	headSizeSlider.setMaximum(2);
    	headSizeSlider.setValue(0.5);
    	setHeadSize();
    	
    	var hsA = new HBox(guiBox);
    	headSizeALabel = new Label(hsA, 0, 0, HS_A_TEXT + headSizeA.int() + "px");
    	headSizeABtn = new PushButton(hsA, 0, 0, "get", setHeadSizeA);
    	headSizeABtn.setSize(30, 18);
    	headSizeABtn.setEnabled(false);
    	setHeadSizeA();
    	
    	var hsB = new HBox(guiBox);
    	headSizeBLabel = new Label(hsB, 0, 0, HS_B_TEXT + headSizeB.int() + "px");
    	headSizeBBtn = new PushButton(hsB, 0, 0, "get", setHeadSizeB);
    	headSizeBBtn.setSize(30, 18);
    	headSizeBBtn.setEnabled(false);
    	setHeadSizeB();
   		
    	startFullBtn = new PushButton(guiBox, 0, 0, "fullscreen");
    	startFullBtn.addEventListener(MouseEvent.CLICK, startFull);
    	
		
    	onResize();
    	stage.addEventListener(Event.RESIZE, onResize);
    	
    	
    	camera = Camera.getCamera();
    	camera.setMode(CAM_W, CAM_H, 24);
		video.attachCamera(camera);
		
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }
    
    function startFull(evt:MouseEvent):Void {
    	stage.displayState = StageDisplayState.FULL_SCREEN;
    }
    
    function onEnterFrame(evt:Event):Void {
    	bmpTargetPrev.bitmapData.copyPixels(bmpTarget.bitmapData, bmpTarget.bitmapData.rect, new Point());
    	
    	if (flipCamBtn.getSelected())
			bmpTarget.bitmapData.draw(video, flipCamMat);
    	else
    		bmpTarget.bitmapData.draw(video);
    	
    	
    	var trackRect = null;
    	if (headRect != null) {
    		var offset = 1/4;
    		var tl = headRect.topLeft;
    		var p00 = tl.add(new Point(headRect.width * offset, headRect.height * offset));
    		var p10 = tl.add(new Point(headRect.width * (1-offset), headRect.height * offset));
    		var p01 = tl.add(new Point(headRect.width * offset, headRect.height * (1-offset)));
    		var p11 = tl.add(new Point(headRect.width * (1-offset), headRect.height * (1-offset)));
    		
    		var v00 = blockmatcher.process(bmpTargetPrev.bitmapData, bmpTarget.bitmapData, p00);
    		var v10 = blockmatcher.process(bmpTargetPrev.bitmapData, bmpTarget.bitmapData, p10);
    		var v01 = blockmatcher.process(bmpTargetPrev.bitmapData, bmpTarget.bitmapData, p01);
    		var v11 = blockmatcher.process(bmpTargetPrev.bitmapData, bmpTarget.bitmapData, p11);
    		
    		var c00 = new Point(p00.x - v00.x, p00.y - v00.y);
    		var c10 = new Point(p10.x - v10.x, p10.y - v10.y);
    		var c01 = new Point(p01.x - v01.x, p01.y - v01.y);
    		var c11 = new Point(p11.x - v11.x, p11.y - v11.y);
    		
    		
    		var center = c00.add(c10).add(c01).add(c11);
    		center.x *= 0.25;
    		center.y *= 0.25;
    		
    		var w = ((c10.x - c00.x) + (c11.x - c01.x)) * 0.5 / (offset*2);
    		var h = ((c01.y - c00.y) + (c11.y - c10.y)) * 0.5 / (offset*2);
    		
    		trackRect = new Rectangle(center.x - w * 0.5, center.y - h * 0.5, w, h);
    		
    		
    		var g = trackRectSp.graphics;
    		g.clear();
    		g.lineStyle(2);
    		g.lineGradientStyle(GradientType.LINEAR, [0xFFFFFF, 0x00FF00], [1.0, 1.0], [0, 255]);
    		g.moveTo(p00.x, p00.y);
    		g.lineTo(c00.x, c00.y);
    		g.drawCircle(c00.x, c00.y, 4);
    		g.moveTo(p10.x, p10.y);
    		g.lineTo(c10.x, c10.y);
    		g.drawCircle(c10.x, c10.y, 4);
    		g.moveTo(p01.x, p01.y);
    		g.lineTo(c01.x, c01.y);
    		g.drawCircle(c01.x, c01.y, 4);
    		g.moveTo(p11.x, p11.y);
    		g.lineTo(c11.x, c11.y);
    		g.drawCircle(c11.x, c11.y, 4);
    		
    		g.drawRect(trackRect.x, trackRect.y, trackRect.width, trackRect.height);
    	}
    	
    	var rects = detector.detect(bmpTarget);
		var detectRect = null;
		if ( rects != null && rects.length > 0) {
			if (headRect == null) {
				headRect = rects[0];
				
    			headSizeABtn.setEnabled(true);
    			headSizeBBtn.setEnabled(true);
			}
			
			//choose the result that is closest to current headRect
			var headRectCenter = new Point(headRect.x + headRect.width * 0.5, headRect.y + headRect.height * 0.5);
			detectRect = rects.fold(function(r:Rectangle, min:Array<Dynamic>){
				var d = Point.distance(new Point(r.x + r.width * 0.5, r.y + r.height * 0.5), headRectCenter);
				return d < min[1] ? [r, d] : min;
			}, [null, Math.POSITIVE_INFINITY])[0];
			
			//draw all detection result
			var g = faceRectsSp.graphics;
			g.clear();
			g.lineStyle(1, 0x110000);
			for (r in rects) {
				g.drawRect(r.x, r.y, r.width, r.height);
			}
			
			//draw detectRect
			g.lineStyle(2, 0xFF0000);
			g.drawRect(detectRect.x, detectRect.y, detectRect.width, detectRect.height);
		}
		if (detectRect == null) {
			faceRectsSp.graphics.clear();
		}
		
		
		if (detectRect != null && trackRect == null) {
			headRect.topLeft = Point.interpolate(headRect.topLeft, detectRect.topLeft, 0.7);
			headRect.bottomRight = Point.interpolate(headRect.bottomRight, detectRect.bottomRight, 0.7);
		} else if (detectRect == null && trackRect != null) {
			headRect.topLeft = Point.interpolate(headRect.topLeft, trackRect.topLeft, 0.7);
			headRect.bottomRight = Point.interpolate(headRect.bottomRight, trackRect.bottomRight, 0.7);
		} else if (detectRect != null && trackRect != null) {
			headRect.topLeft = Point.interpolate(headRect.topLeft, Point.interpolate(detectRect.topLeft, trackRect.topLeft, 0.5), 0.5);
			headRect.bottomRight = Point.interpolate(headRect.bottomRight, Point.interpolate(detectRect.bottomRight, trackRect.bottomRight, 0.5), 0.5);
		}
		
		
		if (headRect != null) {
			var g = trackRectSp.graphics;
			g.lineStyle(2, 0xFFFFFF);
			g.drawRect(headRect.x, headRect.y, headRect.width, headRect.height);
		}
		
    	
    	var screenHeight = screenWidth*stage.stageHeight/stage.stageWidth;
    	
    	//screen's bottom left corner
    	var pa = new Vector3D(-screenWidth*0.5, -screenHeight*0.5, 0);
    	
    	//screen's bottom right corner
    	var pb = new Vector3D(screenWidth*0.5, -screenHeight*0.5, 0);
    	
    	//screen's top left corner
    	var pc = new Vector3D(-screenWidth*0.5, screenHeight*0.5, 0);
    	
    	//head position
    	var pe = if (headRect == null || Math.isNaN(headSizeA) || Math.isNaN(headSizeB)) {
    		new Vector3D(0, 0, 2);
    	} else {
    		var headSizeCur = (headRect.width + headRect.height) * 0.5;
    		headPos3d.z = (headSizeA*HS_A_DIST + headSizeB*HS_B_DIST)*0.5 / headSizeCur;
    		var headRectCenter = new Point(headRect.x + headRect.width * 0.5 - CAM_W * 0.5, headRect.y + headRect.height * 0.5 - CAM_H * 0.5);
    		headPos3d.x = headRectCenter.x * headSize/headSizeCur;
    		headPos3d.y = -headRectCenter.y * headSize/headSizeCur;
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