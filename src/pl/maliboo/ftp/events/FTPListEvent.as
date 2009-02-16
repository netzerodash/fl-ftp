package pl.maliboo.ftp.events
{
	import flash.events.Event;
	
	public class FTPListEvent extends Event
	{
		public static const LIST:String = "list";
		
		private var _fileList:Array;
		
		public function FTPListEvent(type:String, fileList:Array)
		{
			super(type);
			_fileList = fileList;
		}

		public function get fileList():Array
		{
			return _fileList.slice();
		}
		
		override public function clone():Event
		{
			return new FTPListEvent(type, fileList);
		}
	}
}