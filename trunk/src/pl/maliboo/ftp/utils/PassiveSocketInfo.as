package pl.maliboo.ftp.utils
{
	
	public final class PassiveSocketInfo
	{
		public var host:String;
		public var port:int;
		public function PassiveSocketInfo(host:String, port:int)
		{
			this.host = host;
			this.port = port
		}

		public static function parseFromReply(pasvReply:String):PassiveSocketInfo
		{
			var match:Array = pasvReply.match(/(\d{1,3},){5}\d{1,3}/);
			if (match == null)
				throw new Error("Error parsing passive port! ("+pasvReply+")");
			var data:Array = match[0].split(",");
			var host:String = data.slice(0,4).join(".");
			var port:int = (parseInt(data[4])<<8)+parseInt(data[5]);
			return new PassiveSocketInfo(host, port);
		}
	}
}