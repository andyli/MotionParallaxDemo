package;

import jp.maaash.objectdetection.ObjectDetector;
import jp.maaash.objectdetection.ObjectDetectorEvent;
import jp.maaash.objectdetection.HaarCascadeLoader;
import flash.events.Event;
import flash.xml.XML;

class MyObjectDetector extends ObjectDetector {
	public function new():Void {
		super();
	}
	
	public function loadHaarCascadesFromXml(xmlStr:String):Void {
		xmlloader = new MyHaarCascadeLoader(xmlStr);
		xmlloader.addEventListener(Event.COMPLETE, onXmlLoaded);
		dispatchEvent(new ObjectDetectorEvent(ObjectDetectorEvent.HAARCASCADES_LOADING));
		xmlloader.load();
	}
}

class MyHaarCascadeLoader extends HaarCascadeLoader {
	var xmlStr:String;
	
	public function new(xmlStr:String):Void{
		super("");
		this.xmlStr = xmlStr;
	}
	
	override public function load():Void {
		decodeHaarCascadeXML(new XML(xmlStr));
		dispatchEvent(new Event(Event.COMPLETE));
	}
}