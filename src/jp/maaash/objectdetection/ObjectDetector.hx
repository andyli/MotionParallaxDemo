//
// Project HxMarilena
// Object Detection in haXe
// based on Project Marilena
// Object Detection in Actionscript3
// based on OpenCV (Open Computer Vision Library) Object Detection
//
// Copyright (C) 2008, Masakazu OHTSUKA (mash), all rights reserved.
// contact o.masakazu(at)gmail.com
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//   * Redistribution's of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//   * Redistribution's in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
// This software is provided by the copyright holders and contributors "as is" and
// any express or implied warranties, including, but not limited to, the implied
// warranties of merchantability and fitness for a particular purpose are disclaimed.
// In no event shall the Intel Corporation or contributors be liable for any direct,
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to, procurement of substitute goods or services;
// loss of use, data, or profits; or business interruption) however caused
// and on any theory of liability, whether in contract, strict liability,
// or tort (including negligence or otherwise) arising in any way out of
// the use of this software, even if advised of the possibility of such damage.
//

package jp.maaash.objectdetection;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.display.Bitmap;
import flash.geom.Rectangle;
import flash.utils.SetIntervalTimer;


class ObjectDetector extends EventDispatcher{
	private var debug     :Bool;
	private var tgt       :TargetImage;
	public  var detected  :Array<Rectangle>;
	public  var cascade   :HaarCascade;
	private var _options  :ObjectDetectorOptions;
	private var xmlloader :HaarCascadeLoader;

	private var waiting   :Bool;
	private var loaded    :Bool;

	public function new()
	{
		super();
		tgt = new TargetImage();
		debug = false;
		waiting = false;
		loaded = false;
	}

	public function detect( bmp:Bitmap = null ):Void
	{
		//trace("[detect]");
		if ( bmp !=null && bmp.bitmapData != null )
		{
			tgt.bitmapData = bmp.bitmapData;
		}

		if ( !loaded )
		{
			waiting = true;
			return;
		}
		dispatchEvent( new ObjectDetectorEvent(ObjectDetectorEvent.DETECTION_START) );
		_detect();
	}

	private function _detect():Void
	{
		detected = new Array<Rectangle>();
		var imgw:Int = tgt.width, imgh:Int = tgt.height;
		var scaledw:Int, scaledh:Int, limitx:Int, limity:Int, stepx:Int, stepy:Int, result:Int, factor:Float = 1;
		factor = 1;
		while (factor * cascade.base_window_w < imgw && factor * cascade.base_window_h < imgh)
		{
			scaledw = Std.int( cascade.base_window_w * factor );
			scaledh = Std.int( cascade.base_window_h * factor );
			if ( scaledw < _options.minSize || scaledh < _options.minSize )
			{
				factor *= _options.scaleFactor; // for loop increment
				continue;
			}
			limitx = tgt.width  - scaledw;
			limity = tgt.height - scaledh;
			if ( _options.endx != ObjectDetectorOptions.INVALID_POS && _options.endy != ObjectDetectorOptions.INVALID_POS )
			{
				limitx = Std.int(Math.min( _options.endx, limitx ));
				limity = Std.int(Math.min( _options.endy, limity ));
			}
			//logger("[detect]limitx,y: "+limitx+","+limity);

			//stepx  = Math.max(_options.MIN_MARGIN_SEARCH,factor);
			stepx  = scaledw>>3;
			stepy  = stepx;
			//logger("[detect] w,h,step: "+scaledw+","+scaledh+","+stepx);

			var ix:Int=0, iy:Int=0, startx:Int=0, starty:Int=0;
			if ( _options.startx != ObjectDetectorOptions.INVALID_POS && _options.starty != ObjectDetectorOptions.INVALID_POS )
			{
				startx =  Std.int(Math.max( ix, _options.startx ));
				starty =  Std.int(Math.max( iy, _options.starty ));
			}
			//logger("[detect]startx,y: "+startx+","+starty);

			//trace("[detect]startx,y: " + startx + "," + starty);
			iy = starty;
			while ( iy < limity )
			{
				ix = startx;
				while ( ix < limitx ) 
				{ 
					if( (_options.searchMode & ObjectDetectorOptions.SEARCH_MODE_NO_OVERLAP) != 0 &&
						overlaps(ix, iy, scaledw, scaledh) )
					{
						// do nothing
					}
					else
					{
						//logger("[checkAndRun]ix,iy,scaledw,scaledh: "+ix+","+iy+","+scaledw+","+scaledh);
						cascade.scale = factor;
						result = runHaarClassifierCascade(cascade,ix,iy,scaledw,scaledh);
						if ( result > 0 )
						{
							var faceArea :Rectangle = new Rectangle(ix,iy,scaledw,scaledh);
							detected.push( faceArea );
							logger("[createCheckAndRun]found!: "+ix+","+iy+","+scaledw+","+scaledh);

							// doesnt mean anything cause detection is not time-divided (now)
							var ev1 :ObjectDetectorEvent = new ObjectDetectorEvent( ObjectDetectorEvent.FACE_FOUND );
							ev1.rect = faceArea;
							dispatchEvent( ev1 );
						}
					}
					ix += stepx; // for loop increment
				}
				iy += stepy; // for loop increment
			}
			factor *= _options.scaleFactor; // for loop increment
		}

		// integrate redundant candidates ...

		var ev2 :ObjectDetectorEvent = new ObjectDetectorEvent( ObjectDetectorEvent.DETECTION_COMPLETE );
		ev2.rects = detected;
		dispatchEvent( ev2 );
	}

	private function runHaarClassifierCascade(c:HaarCascade, x:Int, y:Int, w:Int, h:Int):Int
	{
		//logger("[runHaarClassifierCascade] c:",x,y,w,h);
		var mean :Float                 = tgt.getSum(x,y,w,h) * c.inv_window_area;
		var variance_norm_factor :Float = tgt.getSum2(x,y,w,h)* c.inv_window_area - mean*mean;
		if (variance_norm_factor >= 0)
			variance_norm_factor = Math.sqrt(variance_norm_factor);
		else
			variance_norm_factor = 1;

		var trees = c.trees, treenums:Int = trees.length, tree:FeatureTree, features:Array<FeatureBase>, featurenums:Int, val:Float = 0, sum:Float = 0, feature:FeatureBase, i:Int=0, j:Int=0, st_th:Float = 0;
		for (i in 0...treenums)
		{
			tree        = trees[i];
			features    = tree.features;
			featurenums = features.length;
			val         = 0;
			st_th       = tree.stageThreshold;

			for (j in 0...featurenums)
			{
				feature = features[j];
				sum  = feature.getSum( tgt, x, y );

//					val += (sum < feature.threshold * variance_norm_factor) ?
//						feature.left_val : feature.right_val;
//
//					* Ternary operation causes coersion and makes slower. 

				if (sum < feature.threshold * variance_norm_factor)
					val += feature.leftVal;
				else
					val += feature.rightVal;
				//trace("feature sum = " + sum + " val = " + feature.leftVal + " rv = " + feature.rightVal);
				if ( val > st_th )
				{
					// left_val, right_val are always plus
					break;
				}
			}
			if ( val < st_th )
			{
				//trace(" val<st_th: " + val + " < " + st_th + " given " + featurenums + " features");
				return 0;
			}
		}
		return 1;
	}

	private function overlaps(_x:Int, _y:Int, _w:Int, _h:Int):Bool
	{
		// if the area we're going to check contains, or overlaps the square which is already picked up, ignore it
		var i:Int=0;
		var l:Int=detected.length;
		var tg: Rectangle;
		var x:Int = _x, y:Int = _y, w:Int = _w, h:Int = _h, tx1:Int, tx2:Int, ty1:Int, ty2:Int;
		for (i in 0...l)
		{
			tg = detected[i];
			tx1 = Std.int(tg.x);
			tx2 = Std.int(tg.x + tg.width);
			ty1 = Std.int(tg.y);
			ty2 = Std.int(tg.y + tg.height);
			if(  ( ( x <= tx1 && tx1 < x+w )
				 ||( x <= tx2 && tx2 < x+w ) )
			  && ( ( y <= ty1 && ty1 < y+h )
				 ||( y <= ty2 && ty2 < y+h ) )  )
			{
				return true;
			}
		}
		return false;
	}

	public function loadHaarCascades( url :String ):Void
	{
		xmlloader = new HaarCascadeLoader( url );
		xmlloader.addEventListener(Event.COMPLETE, onXmlLoaded);
		loaded = false;
		dispatchEvent( new ObjectDetectorEvent(ObjectDetectorEvent.HAARCASCADES_LOADING) );
		xmlloader.load();	// kick it!
	}
	
	private function onXmlLoaded(e:Event):Void 
	{
		xmlloader.removeEventListener(Event.COMPLETE, onXmlLoaded);
		dispatchEvent( new ObjectDetectorEvent(ObjectDetectorEvent.HAARCASCADES_LOAD_COMPLETE) );
		cascade = xmlloader.cascade;

		loaded = true;
		if ( waiting )
		{
			waiting = false;
			detect();
		}
	}

	public var bitmap(null, setBitmap):Bitmap;
	public function setBitmap( bmp:Bitmap ):Bitmap
	{
		tgt.bitmapData = bmp.bitmapData;
		return bmp;
	}
	
	public var options(null, setOptions):ObjectDetectorOptions;
	public function setOptions( opt:ObjectDetectorOptions ):ObjectDetectorOptions
	{
		_options = opt;
		return opt;
	}

	private function logger(args):Void{
		if (!debug) { return; }
		trace("[ObjectDetector]" + args);
		//log(["[ObjectDetector]"+args.shift()].concat(args));
	}
}