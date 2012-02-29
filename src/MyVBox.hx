package;

import com.bit101.components.VBox;

class MyVBox extends VBox {
	override public function draw():Void {
		super.draw();
		
		var border = 5;
		graphics.clear();
		graphics.beginFill(0xFFFFFF);
   		graphics.drawRect(-border, -border, _width + border + border, _height + border + border);
   		graphics.endFill();
	}
}