package pl.maliboo.ftp
{
	import flash.net.Socket;
	
	internal class FTPSocket extends Socket
	{
		public function FTPSocket(host:String=null, port:int=0)
		{
			super(host, port);
		}
	}
}