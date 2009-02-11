package pl.maliboo.ftp
{
	public class FTPFile
	{
		//TODO:remote-path??!?! Moznaby stosowac jako kolejke!?
		public function FTPFile()
		{
		}


		public function get filePermissions():uint
		{
			return 0;
		}
		
		public function get creationDate:Date
		{
			return new Date();
		}
		
		public function get creator:String
		{
			return "";
		}
		
		public function get extension:String
		{
			return "";
		}

		public function get modificationDate:Date
		{
			return new Date();
		}
		
		public function get name:String
		{
			return "";
		}
		
		public function get size:uint
		{
			return 0;
		}
		
		
		public function get type:String
		{
			return "";
		}
		
		
		public function get isDirectory:Boolean
		{
			return false;
		}
		
		public function get isHidden:Boolean
		{
			return false;
		}
		
		public function get isSymbolicLink:Boolean
		{
			return false;
		}
		
		public function get nativePath:String
		{
			return "";
		}
		
/*		public function get parent:File
		{
		}*/
		
		public function get url:String
		{
			return "";
		}
		
		
		public function hasPermission(access:uint, permission:uint):Boolean
		{
			return (filePermissions%(10*access)/access>>0) & permission;
		}
}