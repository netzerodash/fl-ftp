package pl.maliboo.ftp
{
	import flexunit.framework.TestCase;
	
	public class FTPCommandTest extends TestCase
	{
		
		public function FTPCommandTest(methodName:String=null)
		{
			super(methodName);
		}
		
		
		public function testClone():void
		{
			var cmd:FTPCommand;
			cmd = new FTPCommand("SOME_NAME");
			assertTrue("Commands should be the same!", cmd.clone().name == cmd.name);
			
			cmd = new FTPCommand("SOME_NAME_2", ["arg1", "arg2"]);
			assertTrue("Commands should be the same!", cmd.clone().name == cmd.name);
			assertTrue("Commands should be the same!", cmd.clone().args.length == cmd.args.length);
			assertTrue("Commands should be the same! ("+cmd.clone().rawBody+" and "+cmd.rawBody+")", cmd.clone().rawBody == cmd.rawBody);
		}
		
		public function testFTPCommand():void
		{
			var cmd:FTPCommand;
			cmd = new FTPCommand("SOME_NAME_2");
			assertTrue(cmd.name == "SOME_NAME_2");
			assertTrue(cmd.rawBody == cmd.name);
			
			cmd = new FTPCommand("SOME_NAME_2", []);
			assertTrue(cmd.name == "SOME_NAME_2");
			assertTrue(cmd.rawBody == cmd.name);
			
			cmd = new FTPCommand("SOME_NAME_2", ["arg1"]);
			assertTrue(cmd.name == "SOME_NAME_2");
			assertTrue(cmd.rawBody == "SOME_NAME_2 arg1");
			assertTrue(cmd.args.length == 1);
			assertTrue(cmd.args[0] == "arg1");
			
			cmd = new FTPCommand("SOME_NAME_2", ["arg2", "arg3"]);
			assertTrue(cmd.name == "SOME_NAME_2");
			assertTrue(cmd.rawBody == "SOME_NAME_2 arg2 arg3");
			assertTrue(cmd.args.length == 2);
			assertTrue(cmd.args[0] == "arg2");
			assertTrue(cmd.args[1] == "arg3");
		}
	}
}