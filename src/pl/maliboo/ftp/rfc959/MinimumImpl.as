package pl.maliboo.ftp.rfc959
{
	public final class MinimumImpl
	{
		public static const TYPE:String = "ASCII Non-print";
		public static const MODE:String = "Stream";
		public static const STRUCTURE:Array = "File,Record".split(",");
		//PAMIETAC o PASV!
		public static const COMMANDS:Array = "USER,QUIT,PORT,TYPE,MODE,STRU,RETR,STOR,NOOP".split(",");
		
		public static function meetRequirements(req:String):Boolean
		{
			return true;
		}
	}
}