package pl.maliboo.ftp
{
	public final class FilePermissions
	{
		public static const NO_PERMISSIONS:uint 	= 0;
		public static const EXECUTE:uint 			= 1;
		public static const WRITE:uint 				= 2;
		public static const WRITE_EXECUTE:uint 		= 3;
		public static const READ:uint 				= 4;
		public static const READ_EXECUTE:uint 		= 5;
		public static const READ_WRITE:uint 		= 6;
		public static const READ_WRITE_EXECUTE:uint = 7;
		
		public static const USER:uint = 100;
		public static const GROUP:uint = 10;
		public static const OTHER:uint = 1;
	}
}