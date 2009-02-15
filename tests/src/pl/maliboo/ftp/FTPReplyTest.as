package pl.maliboo.ftp
{
	import flexunit.framework.TestCase;
	
	public class FTPReplyTest extends TestCase
	{		
		
		public function FTPReplyTest(methodName:String=null)
		{
			super(methodName);
		}
		
		
		public function testFTPReplyCorrect():void
		{
			var reply:FTPReply = new FTPReply("226 Since you see this ABOR must've succeeded");
		}
		
		public function testFTPReplyCorrectMultiline():void
		{
			var reply:FTPReply = new FTPReply(
			"230-User flftp@maliboo.dmkhosting.net has group access to:  maliboo\r\n" + 
			"230-OK. Current restricted directory is /\r\n" + 
			"230 0 Kbytes used (0%) - authorized: 25600 Kb");
		}
		
		public function testFTPReplyIncorrect():void
		{
			var reply:FTPReply;
			try
			{
				reply = new FTPReply("226-Since you see this ABOR must've succeeded");
			}
			catch (e:Error){}
			assertNull("Reply should be null", reply);
			
			try
			{
				reply = new FTPReply("ABC-Since you see this ABOR must've succeeded");
			}
			catch (e:Error){}
			assertNull("Reply should be null", reply);
			
			try
			{
				reply = new FTPReply("1BC-Since you see this ABOR must've succeeded");
			}
			catch (e:Error){}
			assertNull("Reply should be null", reply);
		}
		
		public function testFTPReplyIncorrectMultiline():void
		{
			var reply:FTPReply;
			try
			{
				reply = new FTPReply(
				"230 User flftp@maliboo.dmkhosting.net has group access to:  maliboo\r\n" + 
				"230-OK. Current restricted directory is /\r\n" + 
				"230 0 Kbytes used (0%) - authorized: 25600 Kb");
			}
			catch (e:Error){}
			assertNull("Reply should be null", reply);
			
			try
			{
				reply = new FTPReply(
				"230-User flftp@maliboo.dmkhosting.net has group access to:  maliboo\r\n" + 
				"230-OK. Current restricted directory is /\r\n" + 
				"230-0 Kbytes used (0%) - authorized: 25600 Kb");
			}
			catch (e:Error){}
			assertNull("Reply should be null", reply);
			
			try
			{
				reply = new FTPReply(
				"230-User flftp@maliboo.dmkhosting.net has group access to:  maliboo\r\n" + 
				"230-OK. Current restricted directory is /\r\n" + 
				"ABC 0 Kbytes used (0%) - authorized: 25600 Kb");
			}
			catch (e:Error){}
			assertNull("Reply should be null", reply);
		}
		
		public function testClone():void
		{
			var reply:FTPReply = new FTPReply("226 Since you see this ABOR must've succeeded");
			var clone:FTPReply = reply.clone();
			assertTrue("Bodies should be the same.", reply.rawBody == clone.rawBody);
			assertTrue("Codes should be the same.", reply.code == clone.code);
		}
	}
}