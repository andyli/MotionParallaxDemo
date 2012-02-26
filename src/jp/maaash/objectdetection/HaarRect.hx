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


class HaarRect 
{
	public  var dx:Int;	// default values read from xml
	public  var dy:Int;
	public  var dw:Int;
	public  var dh:Int;
	public  var dweight:Float;
	public  var sx:Int;	// scaled values
	public  var sy:Int;
	public  var sw:Int;
	public  var sh:Int;
	public  var sweight:Float;
	
	public function new(s:String)
	{
		var a:Array<String> = s.split(" ");	// something like "3 7 14 4 -1."
		dx      = Std.parseInt(a[0]);
		dy      = Std.parseInt(a[1]);
		dw      = Std.parseInt(a[2]);
		dh      = Std.parseInt(a[3]);
		dweight = Std.parseFloat(a[4]);
	}
	
	public var area(getArea, null):Int;
	public function getArea():Int
	{
		return sw*sh;
	}
	
	public var scale(null, setScale):Float;
	private function setScale(s:Float):Float
	{
		sx = Std.int( dx * s );
		sy = Std.int( dy * s );
		sw = Std.int( dw * s );
		sh = Std.int( dh * s );
		return s;
	}
	
	public var scaleWeight(null, setScaleWeight):Float;
	private function setScaleWeight(s:Float):Float
	{
		sweight = dweight * s;
		return sweight;
	}
	
}