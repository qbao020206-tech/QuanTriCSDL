using System;
using System.Data.SqlClient;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace CongCafe
{
    /// <summary>
    /// LoginForm: Modern, flat design dengan gradient, animations, password visibility toggle
    /// </summary>
    public partial class LoginForm : Form
    {
        // ===== CONTROLS =====
        private CustomRoundedTextBox txtUser;
        private CustomRoundedTextBox txtPass;
        private CustomButton btnLogin;
        private CheckBox chkShowPassword;
        private Label lblError;
        private Label lblBrandName;
        private Label lblTagline;

        // ===== ANIMATION STATE =====
        private Timer animationTimer;
        private float fadeProgress = 0f;
        private bool isAnimating = false;
        private bool isLoggingIn = false;

        public LoginForm()
        {
            Text = "Cộng Cà Phê - Đăng Nhập";
            Size = new Size(900, 550);
            StartPosition = FormStartPosition.CenterScreen;
            BackColor = ThemeHelper.CongBeige;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;

            // ===== LEFT PANEL: BRANDING =====
            Panel pnlBranding = new Panel
            {
                Location = new Point(0, 0),
                Size = new Size(350, 550),
                BackColor = ThemeHelper.CongGreen,
                Dock = DockStyle.Left
            };

            // Logo placeholder (simplified coffee cup icon text)
            lblBrandName = new Label
            {
                Text = "☕ CỘNG CÀ PHÊ",
                Location = new Point(20, 120),
                Size = new Size(310, 80),
                Font = new Font("Segoe UI", 24, FontStyle.Bold),
                ForeColor = Color.White,
                TextAlign = ContentAlignment.TopCenter,
                AutoSize = false
            };

            lblTagline = new Label
            {
                Text = "Quản lý bán hàng\ncơm - cà phê - nước ngọt",
                Location = new Point(20, 220),
                Size = new Size(310, 100),
                Font = new Font("Segoe UI", 12, FontStyle.Regular),
                ForeColor = Color.FromArgb(230, 230, 220),
                TextAlign = ContentAlignment.TopCenter,
                AutoSize = false
            };

            pnlBranding.Controls.AddRange(new Control[] { lblBrandName, lblTagline });

            // ===== RIGHT PANEL: LOGIN FORM =====
            Panel pnlForm = new Panel
            {
                Location = new Point(350, 0),
                Size = new Size(550, 550),
                Dock = DockStyle.Right,
                BackColor = ThemeHelper.CongBeige
            };

            // Title
            Label lblTitle = new Label
            {
                Text = "Đăng Nhập",
                Location = new Point(50, 80),
                Size = new Size(450, 40),
                Font = new Font("Segoe UI", 28, FontStyle.Bold),
                ForeColor = ThemeHelper.CongBrown,
                AutoSize = false
            };

            // Error label
            lblError = new Label
            {
                Text = "",
                Location = new Point(50, 130),
                Size = new Size(450, 20),
                Font = new Font("Segoe UI", 9, FontStyle.Regular),
                ForeColor = ThemeHelper.CongRed,
                AutoSize = false
            };

            // Username label
            Label lblUserLabel = new Label
            {
                Text = "Tài Khoản",
                Location = new Point(50, 160),
                AutoSize = true,
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                ForeColor = ThemeHelper.CongBrown
            };

            // Username textbox
            txtUser = new CustomRoundedTextBox
            {
                Location = new Point(50, 185),
                Size = new Size(450, 40),
                Font = new Font("Segoe UI", 11),
                Text = ""
            };

            // Password label
            Label lblPassLabel = new Label
            {
                Text = "Mật Khẩu",
                Location = new Point(50, 240),
                AutoSize = true,
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                ForeColor = ThemeHelper.CongBrown
            };

            // Password textbox
            txtPass = new CustomRoundedTextBox
            {
                Location = new Point(50, 265),
                Size = new Size(450, 40),
                Font = new Font("Segoe UI", 11),
                UseSystemPasswordChar = true
            };

            // Show password checkbox
            chkShowPassword = new CheckBox
            {
                Location = new Point(70, 320),
                Size = new Size(150, 20),
                Text = "Hiển thị mật khẩu",
                Font = new Font("Segoe UI", 9),
                ForeColor = ThemeHelper.CongBrown,
                BackColor = ThemeHelper.CongBeige
            };
            chkShowPassword.CheckedChanged += ChkShowPassword_CheckedChanged;

            // Login button
            btnLogin = new CustomButton
            {
                Location = new Point(50, 360),
                Size = new Size(450, 45),
                Text = "Đăng Nhập",
                Font = new Font("Segoe UI", 12, FontStyle.Bold),
                BackColor = ThemeHelper.CongGreen,
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnLogin.FlatAppearance.BorderSize = 0;
            btnLogin.Click += BtnLogin_Click;

            // Forgot password link
            LinkLabel lnkForgotPassword = new LinkLabel
            {
                Location = new Point(50, 420),
                Size = new Size(450, 20),
                Text = "Quên mật khẩu?",
                Font = new Font("Segoe UI", 9),
                LinkColor = ThemeHelper.CongGreen,
                ActiveLinkColor = ThemeHelper.CongHighlight,
                AutoSize = false,
                TextAlign = ContentAlignment.MiddleCenter
            };
            lnkForgotPassword.LinkClicked += (s, e) =>
            {
                MessageBox.Show("Vui lòng liên hệ quản trị viên để reset mật khẩu.", "Quên Mật Khẩu",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
            };

            pnlForm.Controls.AddRange(new Control[] { 
                lblTitle, lblError, lblUserLabel, txtUser, 
                lblPassLabel, txtPass, chkShowPassword, 
                btnLogin, lnkForgotPassword 
            });

            Controls.AddRange(new Control[] { pnlBranding, pnlForm });

            // ===== ANIMATIONS =====
            animationTimer = new Timer { Interval = 16 }; // ~60 FPS
            animationTimer.Tick += AnimationTimer_Tick;
            animationTimer.Start();
            isAnimating = true;

            // Input validation
            txtUser.TextChanged += TxtUser_TextChanged;
            txtPass.TextChanged += TxtPass_TextChanged;
        }

        private void AnimationTimer_Tick(object sender, EventArgs e)
        {
            if (isAnimating && fadeProgress < 1f)
            {
                fadeProgress += 0.05f;
                this.Opacity = Math.Min(1f, fadeProgress);
                if (fadeProgress >= 1f)
                {
                    isAnimating = false;
                    animationTimer.Stop();
                }
            }
        }

        private void ChkShowPassword_CheckedChanged(object sender, EventArgs e)
        {
            txtPass.UseSystemPasswordChar = !chkShowPassword.Checked;
        }

        private void TxtUser_TextChanged(object sender, EventArgs e)
        {
            ValidateForm();
        }

        private void TxtPass_TextChanged(object sender, EventArgs e)
        {
            ValidateForm();
        }

        private void ValidateForm()
        {
            bool isValid = true;

            if (string.IsNullOrWhiteSpace(txtUser.Text))
            {
                isValid = false;
            }

            if (txtPass.Text.Length < 6)
            {
                isValid = false;
            }

            btnLogin.Enabled = isValid;

            if (!isValid && !string.IsNullOrWhiteSpace(txtPass.Text) && txtPass.Text.Length < 6)
            {
                lblError.Text = "Mật khẩu phải có ít nhất 6 ký tự";
            }
            else
            {
                lblError.Text = "";
            }
        }

        private void BtnLogin_Click(object sender, EventArgs e)
        {
            if (isLoggingIn) return;

            string username = txtUser.Text.Trim();
            string password = txtPass.Text.Trim();

            if (string.IsNullOrWhiteSpace(username))
            {
                lblError.Text = "Vui lòng nhập tài khoản";
                return;
            }

            if (password.Length < 6)
            {
                lblError.Text = "Mật khẩu phải có ít nhất 6 ký tự";
                return;
            }

            isLoggingIn = true;
            btnLogin.Text = "Đang đăng nhập...";
            btnLogin.Enabled = false;

            GlobalState.Username = username;
            GlobalState.Password = password;

            try
            {
                using (SqlConnection conn = new SqlConnection(GlobalState.GetConnectionString()))
                {
                    conn.Open();
                    this.DialogResult = DialogResult.OK;
                    this.Close();
                }
            }
            catch (Exception ex)
            {
                lblError.Text = "Đăng nhập thất bại. Kiểm tra lại thông tin.";
                MessageBox.Show("Lỗi: " + ex.Message, "Đăng Nhập Lỗi", 
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                isLoggingIn = false;
                btnLogin.Text = "Đăng Nhập";
                btnLogin.Enabled = true;
            }
        }
    }

    // ===== CUSTOM CONTROLS =====

    /// <summary>
    /// CustomRoundedTextBox: TextBox with rounded corners
    /// </summary>
    public class CustomRoundedTextBox : TextBox
    {
        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);

            // Vẽ border rounded
            Rectangle rect = new Rectangle(0, 0, Width - 1, Height - 1);
            UIHelper.DrawRoundedRectangleBorder(e.Graphics, rect, 8, ThemeHelper.CongGreen, 2);
        }
    }

    /// <summary>
    /// CustomButton: Button with rounded corners
    /// </summary>
    public class CustomButton : Button
    {
        public CustomButton()
        {
            FlatStyle = FlatStyle.Flat;
            FlatAppearance.BorderSize = 0;
            Cursor = Cursors.Hand;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Rectangle rect = new Rectangle(0, 0, Width - 1, Height - 1);

            Color bgColor = Enabled ? (Focused || Hovered ? ThemeHelper.CongHighlight : BackColor) : Color.LightGray;
            Color textColor = Enabled ? ForeColor : Color.DarkGray;

            UIHelper.DrawRoundedRectangleFill(e.Graphics, rect, 8, bgColor);

            StringFormat format = new StringFormat
            {
                Alignment = StringAlignment.Center,
                LineAlignment = StringAlignment.Center
            };

            using (SolidBrush brush = new SolidBrush(textColor))
            {
                e.Graphics.DrawString(Text, Font, brush, rect, format);
            }
        }

        private bool Hovered = false;

        protected override void OnMouseEnter(EventArgs e)
        {
            Hovered = true;
            Invalidate();
            base.OnMouseEnter(e);
        }

        protected override void OnMouseLeave(EventArgs e)
        {
            Hovered = false;
            Invalidate();
            base.OnMouseLeave(e);
        }
    }
}