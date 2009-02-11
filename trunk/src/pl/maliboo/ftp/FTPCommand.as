package pl.maliboo.ftp
{
	internal class FTPCommand
	{
		private  static const ARGS_SEPARATOR:String = " ";
		
		private var _name:String;
		private var _args:Array;
		private var _response:FTPResponse;
		
		public function FTPCommand(name:String, args:Array=null)
		{
			_name = name;
			_args = args? args : [];
		}
		
		public function get response():FTPResponse
		{
			return _response;
		}
		
		public function get name():String
		{
			return _name;
		}
		
		public function get args():Array
		{
			return _args.splice();
		}
		
		public function get rawBody():String
		{
			return name + ARGS_SEPARATOR + _args.join(ARGS_SEPARATOR);
		}
		
		public function clone():FTPCommand
		{
			return new FTPCommand(name, args);
		}
	}
}