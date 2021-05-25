using System;
using System.Data.SqlClient;
using static System.Console;

namespace BasicSQL
{
    class Program
    {
        static void Main(string[] args)
        {
            ColorPrint.UserInput("Connect to Servername");
            string currServer = Console.ReadLine();
            SqlConnection currentCon = Connect(currServer);

            while (true)
            {
                ColorPrint.Prompt(currServer);
                string x = Console.ReadLine();
                if (x == "q") break;

                switch (x)
                {
                    case "q":
                        return;
                    default:
                        try
                        {
                            Query(x, currentCon);
                        }
                        catch (Exception e)
                        {
                            ColorPrint.Error(e.Message);
                        }
                        break;
                }
            }
            currentCon.Close();
        }

        public static void Query(string query, SqlConnection con)
        {
            SqlCommand command = new SqlCommand(query, con);
            SqlDataReader reader = command.ExecuteReader();
            while (reader.Read())
            {
                ColorPrint.Result(reader[0].ToString());
            }
            reader.Close();
        }

        public static SqlConnection Connect(string sqlServer)
        {
            String database = "master";
            String conString = "Server = " + sqlServer + "; Database = " + database + "; Integrated Security = True; MultipleActiveResultSets = True;";
            SqlConnection con = new SqlConnection(conString);
            try
            {
                con.Open();
                ColorPrint.Success("auth to " + sqlServer + " success!");
                String querylogin = "SELECT SYSTEM_USER;";
                SqlCommand command = new SqlCommand(querylogin, con);
                SqlDataReader reader = command.ExecuteReader();
                reader.Read();
                ColorPrint.Info("logged in as: " + reader[0]);
                reader.Close();
            }
            catch
            {
                ColorPrint.Error("auth failed");
            }
            return con;
        }
    }

    internal static class ColorPrint
    {
        public static string GRAY = "\x1b[1;37m";
        public static string DGRAY = "\x1b[1;90m";
        static string RED = "\x1b[1;31m";
        public static string LRED = "\x1b[1;31m";
        static string GREEN = "\x1b[1;32m";
        static string LGREEN = "\x1b[1;32m";
        public static string YELLOW = "\x1b[33m";
        static string LYELLOW = "\x1b[1;33m";
        static string BLUE = "\x1b[34m";
        public static string LBLUE = "\x1b[1;34m";
        static string MAGENTA = "\x1b[1:35m";
        static string CYAN = "\x1b[36m";
        static string LCYAN = "\x1b[1;36m";
        public static string NOCOLOR = "\x1b[0m";

        public static void Prompt(string toPrint)
        {
            Console.Write(DGRAY + toPrint + "> " + NOCOLOR);
        }

        public static void UserInput(string toPrint)
        {
            Console.Write(LYELLOW + toPrint + "> " + NOCOLOR);
        }
        public static void Success(string toPrint)
        {
            Console.WriteLine(GREEN + "[+] " + toPrint + NOCOLOR);
        }

        public static void Result(string toPrint)
        {
            Console.WriteLine(GREEN + "[+] " + toPrint + NOCOLOR);
        }

        public static void Info(string toPrint)
        {
            Console.WriteLine(BLUE + "[+] " + toPrint + NOCOLOR);
        }

        public static void Error(string toPrint)
        {
            Console.WriteLine(RED + "[+] " + toPrint + NOCOLOR);
        }
    }
}
