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


class Feature3Rects extends FeatureBase
{

	public var r1:HaarRect;
	public var r2:HaarRect;
	public var r3:HaarRect;
	
	public function new(_t:Int, _th:Float, _lv:Float, _rv:Float) 
	{
		super(_t, _th, _lv, _rv);
	}	

	override public function getSum(t:TargetImage, offsetX:Int, offsetY:Int):Float
	{
		var sum:Float = 0;
		sum += t.getSum( offsetX + r1.sx, offsetY + r1.sy, r1.sw, r1.sh ) * r1.sweight;
		sum += t.getSum( offsetX + r2.sx, offsetY + r2.sy, r2.sw, r2.sh ) * r2.sweight;
		sum += t.getSum( offsetX + r3.sx, offsetY + r3.sy, r3.sw, r3.sh ) * r3.sweight;
		return sum;
	}
	
	override public function setScaleAndWeight(s:Float, w:Float):Void
	{
		r2.scale = s;
		r2.scaleWeight = w;
		r3.scale = s;
		r3.scaleWeight = w;
		r1.scale = s;
		r1.sweight = -( r2.area * r2.sweight + r3.area * r3.sweight ) / r1.area;
	}
	
	override public function setRect(r:HaarRect, i:Int):Void
	{
		switch(i) 
		{
			case 0:
				r1 = r;
			case 1:
				r2 = r;
			case 2:
				r3 = r;
		}
	}
	
}