package pl.maliboo.ftp.rfc959
{
	public final class ReplyType
	{
		
		public static const UNKNOWN:int = 		0;
		
		public static const POSITIVE:int = 		1<<0;
		public static const NEGATIVE:int = 		1<<1;
		
		public static const CONTINUABLE:int = 	1<<2
		public static const UNCONTINUABLE:int =	1<<3
		
		private static const PRELIMINARY:int = 	1<<4;
		private static const COMPLETION:int = 	1<<5;
		private static const INTERMEDIATE:int =	1<<6;
		private static const TRANSIENT:int = 	1<<7;
		private static const PERMANENT:int = 	1<<8;
		
		public static const POSITIVE_PRELIMINARY:int = 	POSITIVE | UNCONTINUABLE | PRELIMINARY;
		public static const POSITIVE_COMPLETION:int = 	POSITIVE | UNCONTINUABLE | COMPLETION;
		public static const POSITIVE_INTERMEDIATE:int = POSITIVE | CONTINUABLE | INTERMEDIATE;
		public static const NEGATIVE_TRANSIENT:int = 	NEGATIVE | CONTINUABLE | TRANSIENT;
		public static const NEGATIVE_PERMANENT:int = 	NEGATIVE | UNCONTINUABLE | PERMANENT;
		
		
		public static function getType(code:int):int
		{
			switch (code/100>>0)
			{
				case 1:
					return POSITIVE_PRELIMINARY;
				case 2:
					return POSITIVE_COMPLETION;
				case 3:
					return POSITIVE_INTERMEDIATE;
				case 4:
					return NEGATIVE_TRANSIENT;
				case 5:
					return NEGATIVE_PERMANENT;
				default:
					return 0;
			}
		}
	}
}