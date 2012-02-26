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
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.xml.XML;
//import haxe.xml.Fast;

class HaarCascadeLoader extends EventDispatcher 
{
	private var debug:Bool;
	//private var ziploader:ZipLoader;
	private var urlloader:URLLoader;
	private var urlrequest:URLRequest;
	public var cascade:HaarCascade;
	
	public function new(url:String) 
	{
		super();
		cascade = new HaarCascade();
		urlloader = new URLLoader();
		urlrequest = new URLRequest(url);
		urlloader.addEventListener(Event.COMPLETE, onDataLoaded);
		/*ziploader = new ZipLoader();
		ziploader.url = url;
		ziploader.addEventListener(Event.COMPLETE, function(e:Event):Void {
			//logger("[Event.COMPLETE]e: " + e);
			ziploader.removeEventListener(Event.COMPLETE, this);
			decodeHaarCascadeXML( new XML(ziploader.getContentAsString()) );
			dispatchEvent( new Event(Event.COMPLETE) );
		});
		*/
	}
	
	private function onDataLoaded(e:Event):Void
	{
		//logger("[Event.COMPLETE]e: " + e);
		urlloader.removeEventListener(Event.COMPLETE, onDataLoaded);
		decodeHaarCascadeXML(  new XML(urlloader.data) );
		dispatchEvent( new Event(Event.COMPLETE) );
	}
	
	public function load():Void 
	{
		urlloader.load(urlrequest);
		//ziploader.load();
	}
	
	private function decodeHaarCascadeXML(x:XML):Void
	{
		//logger("[decodeHaarCascadeXML]x: ",x);
		var size:String = x.children()[0].size.toString();
		cascade.base_window_w = Std.parseInt(size.split(" ")[0]);
		cascade.base_window_h = Std.parseInt(size.split(" ")[1]);
		//trace("loading haar.. basewin_w = " + cascade.base_window_w);
		var stages:XML = x.children()[0].stages[0];
		var stage_nums:Int = stages._.length();
		//logger("stage_nums: ",stage_nums);

		var stagexml     :XML;
		var treexml      :XML;
		var tree         :FeatureTree;
		var feature_nums :Int;
		var featurexml   :XML;
		var rects        :XML;
		var rectnums     :Int;
		var rect1        :HaarRect;
		var rect2        :HaarRect;
		var rect3        :HaarRect;
		var feature      :FeatureBase = null;
		for (i in 0...stage_nums)
		{	// trees
			stagexml = stages._[i];
			treexml  = stagexml.trees[0];
			tree     = new FeatureTree();
			tree.stageThreshold = Std.parseFloat(stagexml.stage_threshold[0].toString());
			feature_nums = treexml._.length();
			//logger("feature_nums: ",feature_nums);
			for (j in 0...feature_nums)
			{
				featurexml = treexml._[j]._[0];
				rects      = featurexml.feature[0].rects[0];
				rectnums   = rects._.length();
				rect1      = new HaarRect(rects._[0].toString());
				rect2      = new HaarRect(rects._[1].toString());
				//trace("rectnums = " + featurexml.left_val[0].toString());
				switch(rectnums){
				case 2:
					feature = new Feature2Rects(
						Std.parseInt(featurexml.tilted.toString()),
						Std.parseFloat(featurexml.threshold[0].toString()), 
						Std.parseFloat(featurexml.left_val[0].toString()),
						Std.parseFloat(featurexml.right_val[0].toString())
					);
					feature.setRect(rect1,0);
					feature.setRect(rect2,1);
				case 3:
					feature = new Feature3Rects(
						Std.parseInt(featurexml.tilted.toString()),
						Std.parseFloat(featurexml.threshold[0].toString()),
						Std.parseFloat(featurexml.left_val[0].toString()),
						Std.parseFloat(featurexml.right_val[0].toString())
					);
					feature.setRect(rect1,0);
					feature.setRect(rect2,1);
					rect3 = new HaarRect(rects._[2].toString());
					feature.setRect(rect3,2);
				}
				tree.features.push(feature);
			}
			cascade.trees.push(tree);
		}
		//logger("trees: ",cascade.trees);
	}

	private function logger(args):Void
	{
		if(!debug){ return; }
		//log(["[HaarCascadeLoader]"+args.shift()].concat(args));
	}

	
}