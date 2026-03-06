using System.Text;
using System.Threading.Tasks;

namespace XRomConverterGUI
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
            Console.SetOut(new LogWriter(ConversionLog));
        }
        private void Form1_Load(object sender, EventArgs e)
        {

        }

        private void SelectXFolder_Click(object sender, EventArgs e)
        {
            using (FolderBrowserDialog diag = new FolderBrowserDialog())
            {
                if (diag.ShowDialog() == DialogResult.OK)
                {
                    XRomPath.Text = diag.SelectedPath;
                }
            }
        }

        private void XRomPath_TextChanged(object sender, EventArgs e)
        {
            if (XRomPath.Text != "")
            {
                if (Path.Exists(Path.Combine(XRomPath.Text, "../sce_pfs")))
                {
                    XRomErrorText.Text = "The folder \"sce_pfs\" was located within X's app folder. this suggests an NPDRM dump (encrypted). please obtain a decrypted dump.";
                    return;
                }
                if (!Path.Exists(XRomPath.Text))
                {
                    XRomErrorText.Text = "The specified path does not exist";
                    return;
                }

                if (!Path.Exists(Path.Combine(XRomPath.Text, "firstread.bin")))
                {
                    XRomErrorText.Text = "firstread.bin was not found within rom folder.";
                    return;
                }

                using (BinaryReader reader = new BinaryReader(File.OpenRead(Path.Combine(XRomPath.Text, "firstread.bin"))))
                {
                    char[] magic = reader.ReadChars(4);
                    if (!(magic[0] == 'D' || magic[1] == 'I' || magic[2] == 'V' || magic[3] == 'A') && !(magic[0] == 'A' || magic[1] == 'D' || magic[2] == 'C' || magic[3] == 'T'))
                    {
                        XRomErrorText.Text = "firstread.bin magic was neither \"DIVA\" or \"ADCT\". this suggests an NPDRM dump (encrypted). please obtain a decrypted dump.";
                        return;
                    }
                }
            }
        }

        private void SelectMMPath_Click(object sender, EventArgs e)
        {
            using (FolderBrowserDialog diag = new FolderBrowserDialog())
            {
                if (diag.ShowDialog() == DialogResult.OK)
                {
                    MMPath.Text = diag.SelectedPath;
                }
            }
        }

        private void MMPath_TextChanged(object sender, EventArgs e)
        {

        }

        private void SelectMMModsPath_Click(object sender, EventArgs e)
        {
            using (FolderBrowserDialog diag = new FolderBrowserDialog())
            {
                if (diag.ShowDialog() == DialogResult.OK)
                {
                    MMModsPath.Text = diag.SelectedPath;
                }
            }
        }

        private async void Convert_Click(object sender, EventArgs e)
        {
            List<string> args = new List<string>() { XRomPath.Text, MMPath.Text, Path.Combine(MMModsPath.Text, "X Rob Conversion") };
            if (!EnableShadows.Checked)
            {
                args.Add("-s");
            }

            ConversionLog.Text = "";
            Convert.Enabled = false;
            Cursor = Cursors.WaitCursor;

            try
            {
                await Task.Run(async () => XRomConverter.XRomConverter.Convert(args.ToArray()));
            }
            catch(Exception ex)
            {
                Console.WriteLine("An unhandled exception occurred during conversion:");
                Console.WriteLine(ex.ToString());
            }
            finally
            {
                Convert.Enabled = true;
                Cursor = Cursors.Default;
            }
        }
    }
    public class LogWriter : TextWriter
    {
        private Control mLog;
        public override Encoding Encoding { get { return Encoding.UTF8; } }

        public LogWriter(Control logDest)
        {
            mLog = logDest;
        }

        private void WriteToLog(string text)
        {
            if (mLog == null || mLog.IsDisposed) return;

            if (mLog.InvokeRequired)
            {
                try
                {
                    mLog.BeginInvoke(() =>
                    {
                        if (mLog is TextBoxBase tb) tb.AppendText(text);
                        else mLog.Text += text;
                    });
                }
                catch
                {
                    
                }
            }
            else
            {
                if (mLog is TextBoxBase tb) tb.AppendText(text);
                else mLog.Text += text;
            }
        }

        public override void Write(char value)
        {
            WriteToLog(value.ToString());
        }

        public override void Write(string? value)
        {
            WriteToLog(value ?? "null");
        }

        public override void WriteLine(string? value)
        {
            WriteToLog((value ?? "null") + Environment.NewLine);
        }
    }
}
