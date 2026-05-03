using System;
using System.Data.SqlClient;
using System.Drawing;
using System.Windows.Forms;

namespace CongCafe // Tên namespace của bạn
{
    public partial class LoginForm : Form
    {
        private TextBox txtUser, txtPass;
        private Button btnLogin;

        // ĐÂY LÀ HÀM KHỞI TẠO - Nơi phép thuật xảy ra
        public LoginForm()
        {
            // Bỏ dòng InitializeComponent(); đi nếu có, thay bằng đống code này:
            Text = "Đăng nhập QLY_CONGCAFFE";
            Size = new Size(350, 250);
            StartPosition = FormStartPosition.CenterScreen;

            Label lblU = new Label() { Text = "Tài khoản:", Location = new Point(30, 40), AutoSize = true };
            txtUser = new TextBox() { Location = new Point(120, 40), Width = 150 };

            Label lblP = new Label() { Text = "Mật khẩu:", Location = new Point(30, 80), AutoSize = true };
            txtPass = new TextBox() { Location = new Point(120, 80), Width = 150, UseSystemPasswordChar = true };

            btnLogin = new Button() { Text = "Đăng Nhập", Location = new Point(120, 130), Width = 100 };
            btnLogin.Click += BtnLogin_Click;

            // Dòng này cực kỳ quan trọng: Nó sẽ "gắn" các ô textbox, nút bấm lên Form
            Controls.AddRange(new Control[] { lblU, txtUser, lblP, txtPass, btnLogin });

            ThemeHelper.ApplyTheme(this);
        }

        private void BtnLogin_Click(object sender, EventArgs e)
        {
            GlobalState.Username = txtUser.Text.Trim();
            GlobalState.Password = txtPass.Text.Trim();

            try
            {
                using (SqlConnection conn = new SqlConnection(GlobalState.GetConnectionString()))
                {
                    conn.Open(); // Nếu mở kết nối thành công nghĩa là đúng tài khoản & pass
                    this.DialogResult = DialogResult.OK;
                    this.Close();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Đăng nhập thất bại. Kiểm tra lại thông tin.\n" + ex.Message, "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}