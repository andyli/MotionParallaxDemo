package;

//import haxe.Timer;
import flash.display.BitmapData;
import flash.geom.Vector3D;
import flash.geom.Point;

using org.casalib.util.ColorUtil;

/**
 * It implements the algorithm described in the paper:
 *     Motion Compensated Frame Interpolation by new Block-based Motion Estimation Algorithm
 *     Taehyeun Ha, Member, IEEE, Seongjoo Lee and Jaeseok Kim, Member, IEEE
 */
class BlockMatcher {	
	/**
	 * Size of estimation block.
	 */
	public var M(default, null):Int;
	
	/**
	 * Sampling number.
	 * Higher => faster and less accurate.
	 */
	public var alpha(default, null):Int;
	
	/**
	 * Searching range.
	 */
	public var S(default, null):Int;
	
	/**
	 * Constant affecting the Weighted Correlation Index.
	 * More positive value make it favors vectors that are close to 0,0
	 */
	public var K(default, null):Float;
	
	var alphaSqrOverMSqr:Float;
	var SHalf:Float;
	var mOverAlpha:Int;
	var disWeights:Array<Float>;
	
	public function new():Void {
		//defaults that works for 320*240
		init(25, 2, 20, 0.02);
		
		//defaults that works for 640*480
		//init(40, 8, 40, 0.005);
	}
	
	public function init(_M:Int, _alpha:Int, _S:Int, _K:Float) {
		M = _M;
		alpha = _alpha;
		S = _S;
		K = _K;
		
		alphaSqrOverMSqr = (alpha * alpha) / (M * M);
		SHalf = S * 0.5;
		mOverAlpha = Std.int(M / alpha);
		disWeights = [];
		for (x in Math.floor(-SHalf)...Math.ceil(SHalf)) {
			for (y in Math.floor(-SHalf)...Math.ceil(SHalf)) {
				disWeights.push(1 + K * (x * x + y * y));
			}
		}
		return this;
	}
	
	static function grey(hex:Int):Float {
		return 0.3 * (hex >> 16 & 0xFF) + 0.59 * (hex >> 8 & 0xFF) + 0.11 * (hex & 0xFF);
	}
	
	public function process(img0:BitmapData, img1:BitmapData, img0Pt:Point):Vector3D
	{
		//var t = Timer.stamp();
		
		var	in0 = img0,
			in1 = img1,
			k = Std.int(img0Pt.x),
			l = Std.int(img0Pt.y),
			in0x, in0y, in1x, in1y,
			i = 0,
			in0Rect = img0.rect,
			in1Rect = img1.rect;
		
		
		//x,y is coordinates of the vector. z is WCI.
		var WCImin = new Vector3D(0.0, 0.0, Math.POSITIVE_INFINITY);
		
		
		
		//for each coordinates in the search range
		for (x in Math.floor(-SHalf)...Math.ceil(SHalf)) {
			for (y in Math.floor(-SHalf)...Math.ceil(SHalf)) {
				
				var	totalDiff = 0.0,
					pixelNum = 0;
				
				in0x = k;
				in0y = l;
				in1x = k + x;
				in1y = l + y;
				
				for (j in 0...mOverAlpha) {
					for (i in 0...mOverAlpha) {
						if (in0Rect.contains(in0x, in0y) && in1Rect.contains(in1x, in1y)) {
							
							totalDiff += Math.abs(grey(in1.getPixel(in0x, in0y)) - grey(in0.getPixel(in1x, in1y)));
							++pixelNum;
							
						}
						
						in0x += alpha;
						in1x += alpha;
					}
					in0x = k;
					in0y += alpha;
					in1x = k + x;
					in1y += alpha;
				}
				
				var WCI = (alphaSqrOverMSqr * totalDiff) / pixelNum * disWeights[i++];
				if (WCI < WCImin.z) {
					WCImin.setTo(x, y, WCI);
				}
			}
		}
		//trace(Timer.stamp() - t);
		return WCImin;
	}
	
}