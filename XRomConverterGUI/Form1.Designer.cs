namespace XRomConverterGUI
{
    partial class Form1
    {
        /// <summary>
        ///  Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        ///  Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        ///  Required method for Designer support - do not modify
        ///  the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            XRomPath = new TextBox();
            SelectXFolder = new Button();
            label1 = new Label();
            MMPath = new TextBox();
            SelectMMPath = new Button();
            label2 = new Label();
            MMModsPath = new TextBox();
            SelectMMModsPath = new Button();
            label3 = new Label();
            EnableShadows = new CheckBox();
            XRomErrorText = new Label();
            MMPathErrorText = new Label();
            Convert = new Button();
            ConversionLog = new TextBox();
            SuspendLayout();
            // 
            // XRomPath
            // 
            XRomPath.Location = new Point(12, 27);
            XRomPath.Name = "XRomPath";
            XRomPath.Size = new Size(443, 23);
            XRomPath.TabIndex = 0;
            XRomPath.TextChanged += XRomPath_TextChanged;
            // 
            // SelectXFolder
            // 
            SelectXFolder.Location = new Point(461, 27);
            SelectXFolder.Name = "SelectXFolder";
            SelectXFolder.Size = new Size(143, 23);
            SelectXFolder.TabIndex = 1;
            SelectXFolder.Text = "Select X ROM Folder";
            SelectXFolder.UseVisualStyleBackColor = true;
            SelectXFolder.Click += SelectXFolder_Click;
            // 
            // label1
            // 
            label1.AutoSize = true;
            label1.Location = new Point(12, 9);
            label1.Name = "label1";
            label1.Size = new Size(74, 15);
            label1.TabIndex = 2;
            label1.Text = "X ROM Path:";
            // 
            // MMPath
            // 
            MMPath.Location = new Point(12, 95);
            MMPath.Name = "MMPath";
            MMPath.Size = new Size(443, 23);
            MMPath.TabIndex = 0;
            MMPath.TextChanged += MMPath_TextChanged;
            // 
            // SelectMMPath
            // 
            SelectMMPath.Location = new Point(461, 95);
            SelectMMPath.Name = "SelectMMPath";
            SelectMMPath.Size = new Size(143, 23);
            SelectMMPath.TabIndex = 1;
            SelectMMPath.Text = "Select MM+ Install Path";
            SelectMMPath.UseVisualStyleBackColor = true;
            SelectMMPath.Click += SelectMMPath_Click;
            // 
            // label2
            // 
            label2.AutoSize = true;
            label2.Location = new Point(12, 77);
            label2.Name = "label2";
            label2.Size = new Size(101, 15);
            label2.TabIndex = 2;
            label2.Text = "MM+ Install Path:";
            // 
            // MMModsPath
            // 
            MMModsPath.Location = new Point(12, 154);
            MMModsPath.Name = "MMModsPath";
            MMModsPath.Size = new Size(443, 23);
            MMModsPath.TabIndex = 0;
            // 
            // SelectMMModsPath
            // 
            SelectMMModsPath.Location = new Point(461, 154);
            SelectMMModsPath.Name = "SelectMMModsPath";
            SelectMMModsPath.Size = new Size(143, 23);
            SelectMMModsPath.TabIndex = 1;
            SelectMMModsPath.Text = "Select MM+ Mods Path";
            SelectMMModsPath.UseVisualStyleBackColor = true;
            SelectMMModsPath.Click += SelectMMModsPath_Click;
            // 
            // label3
            // 
            label3.AutoSize = true;
            label3.Location = new Point(12, 136);
            label3.Name = "label3";
            label3.Size = new Size(100, 15);
            label3.TabIndex = 2;
            label3.Text = "MM+ Mods Path:";
            // 
            // EnableShadows
            // 
            EnableShadows.AutoSize = true;
            EnableShadows.Checked = true;
            EnableShadows.CheckState = CheckState.Checked;
            EnableShadows.Location = new Point(12, 183);
            EnableShadows.Name = "EnableShadows";
            EnableShadows.Size = new Size(111, 19);
            EnableShadows.TabIndex = 3;
            EnableShadows.Text = "Enable Shadows";
            EnableShadows.UseVisualStyleBackColor = true;
            // 
            // XRomErrorText
            // 
            XRomErrorText.AutoSize = true;
            XRomErrorText.Location = new Point(12, 53);
            XRomErrorText.Name = "XRomErrorText";
            XRomErrorText.Size = new Size(0, 15);
            XRomErrorText.TabIndex = 2;
            // 
            // MMPathErrorText
            // 
            MMPathErrorText.AutoSize = true;
            MMPathErrorText.Location = new Point(12, 121);
            MMPathErrorText.Name = "MMPathErrorText";
            MMPathErrorText.Size = new Size(0, 15);
            MMPathErrorText.TabIndex = 2;
            // 
            // Convert
            // 
            Convert.Location = new Point(461, 220);
            Convert.Name = "Convert";
            Convert.Size = new Size(143, 23);
            Convert.TabIndex = 4;
            Convert.Text = "Convert";
            Convert.UseVisualStyleBackColor = true;
            Convert.Click += Convert_Click;
            // 
            // ConversionLog
            // 
            ConversionLog.Location = new Point(12, 249);
            ConversionLog.Multiline = true;
            ConversionLog.Name = "ConversionLog";
            ConversionLog.Size = new Size(592, 256);
            ConversionLog.TabIndex = 5;
            // 
            // Form1
            // 
            AutoScaleDimensions = new SizeF(7F, 15F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(616, 517);
            Controls.Add(ConversionLog);
            Controls.Add(Convert);
            Controls.Add(EnableShadows);
            Controls.Add(label3);
            Controls.Add(SelectMMModsPath);
            Controls.Add(MMPathErrorText);
            Controls.Add(label2);
            Controls.Add(SelectMMPath);
            Controls.Add(MMModsPath);
            Controls.Add(XRomErrorText);
            Controls.Add(label1);
            Controls.Add(MMPath);
            Controls.Add(SelectXFolder);
            Controls.Add(XRomPath);
            Name = "Form1";
            Text = "Form1";
            Load += Form1_Load;
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private TextBox XRomPath;
        private Button SelectXFolder;
        private Label label1;
        private TextBox MMPath;
        private Button SelectMMPath;
        private Label label2;
        private TextBox MMModsPath;
        private Button SelectMMModsPath;
        private Label label3;
        private CheckBox EnableShadows;
        private Label XRomErrorText;
        private Label MMPathErrorText;
        private Button Convert;
        private TextBox ConversionLog;
    }
}
