using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Data.SqlClient;

namespace CongCafe
{
    public partial class BanHangForm : Form
    {
        TextBox txtMaNV, txtMaKH, txtMSBan, txtMaBill, txtMaSP, txtSoLuong, txtDonGiaSP;
        ComboBox cbThanhToan;
        DataGridView dgv;
        Label lblTongTien;

        public BanHangForm()
        {
            Text = "Bán Hàng";
            FormBorderStyle = FormBorderStyle.None;
            SetupUI();

            ThemeHelper.ApplyTheme(this);
        }

        private void SetupUI()
        {
            // PANEL HÓA ĐƠN
            Panel pnlHD = new Panel() { Height = 130, Dock = DockStyle.Top, BorderStyle = BorderStyle.FixedSingle };

            // Dòng 1 (Y=20)
            pnlHD.Controls.Add(new Label() { Text = "Mã NV:", Location = new Point(20, 20), AutoSize = true });
            txtMaNV = new TextBox() { Location = new Point(90, 20), Width = 100 };

            pnlHD.Controls.Add(new Label() { Text = "Mã KH (Tùy chọn):", Location = new Point(210, 20), AutoSize = true });
            txtMaKH = new TextBox() { Location = new Point(340, 20), Width = 100 };

            pnlHD.Controls.Add(new Label() { Text = "Bàn:", Location = new Point(460, 20), AutoSize = true });
            txtMSBan = new TextBox() { Location = new Point(510, 20), Width = 100 };

            Button btnMoBan = new Button() { Text = "Mở Bàn", Location = new Point(640, 18), Width = 100 };
            btnMoBan.Click += BtnMoBan_Click;

            Button btnHuyHD = new Button() { Text = "Hủy HĐ", Location = new Point(760, 18), Width = 100, Enabled = GlobalState.IsManager };
            btnHuyHD.Click += BtnHuyHD_Click;

            // Dòng 2 (Y=70)
            pnlHD.Controls.Add(new Label() { Text = "PTTT:", Location = new Point(20, 70), AutoSize = true });
            cbThanhToan = new ComboBox() { Location = new Point(90, 70), Width = 150 };
            cbThanhToan.Items.AddRange(new[] { "Tiền mặt", "Thẻ", "Momo" }); cbThanhToan.SelectedIndex = 0;

            txtMaBill = new TextBox() { Location = new Point(260, 70), Width = 350, ReadOnly = true }; // Rộng ra để chứa mã 18 ký tự

            pnlHD.Controls.AddRange(new Control[] { txtMaNV, txtMaKH, txtMSBan, cbThanhToan, btnMoBan, txtMaBill, btnHuyHD });

            // PANEL CHI TIẾT
            Panel pnlCT = new Panel() { Height = 80, Dock = DockStyle.Top };

            pnlCT.Controls.Add(new Label() { Text = "Mã SP:", Location = new Point(20, 25), AutoSize = true });
            txtMaSP = new TextBox() { Location = new Point(80, 25), Width = 120 };

            pnlCT.Controls.Add(new Label() { Text = "Số Lượng:", Location = new Point(220, 25), AutoSize = true });
            txtSoLuong = new TextBox() { Location = new Point(300, 25), Width = 60 };

            pnlCT.Controls.Add(new Label() { Text = "Đơn Giá:", Location = new Point(380, 25), AutoSize = true });
            txtDonGiaSP = new TextBox() { Location = new Point(460, 25), Width = 120 };

            Button btnThemMon = new Button() { Text = "Thêm Món", Location = new Point(600, 23), Width = 100 };
            btnThemMon.Click += BtnThemMon_Click;

            Button btnHuyMon = new Button() { Text = "Hủy Món", Location = new Point(710, 23), Width = 100 };
            btnHuyMon.Click += BtnHuyMon_Click;

            Button btnThanhToan = new Button() { Text = "THANH TOÁN", Location = new Point(840, 20), Width = 130, Height = 40, BackColor = Color.Teal };
            btnThanhToan.Click += BtnThanhToan_Click;

            pnlCT.Controls.AddRange(new Control[] { txtMaSP, txtSoLuong, txtDonGiaSP, btnThemMon, btnHuyMon, btnThanhToan });

            dgv = new DataGridView() { Dock = DockStyle.Fill, AllowUserToAddRows = false, ReadOnly = true, SelectionMode = DataGridViewSelectionMode.FullRowSelect };
            lblTongTien = new Label() { Text = "Tổng Tiền: 0 VNĐ", Dock = DockStyle.Bottom, Font = new Font("Segoe UI", 16, FontStyle.Bold), Height = 50, TextAlign = ContentAlignment.MiddleRight, ForeColor = Color.Red };

            Controls.Add(dgv);
            Controls.Add(lblTongTien);
            Controls.Add(pnlCT);
            Controls.Add(pnlHD);
        }

        private void BtnMoBan_Click(object sender, EventArgs e)
        {
            var inputs = new[] {
                new SqlParameter("@PTThanhToan", cbThanhToan.Text),
                new SqlParameter("@TGBAN", DateTime.Now),
                new SqlParameter("@MaKH", string.IsNullOrWhiteSpace(txtMaKH.Text) ? (object)DBNull.Value : txtMaKH.Text),
                new SqlParameter("@MaNV", txtMaNV.Text),
                new SqlParameter("@MSBAN", txtMSBan.Text)
            };
            var res = DatabaseHelper.ExecuteProc("sp_ThemHoaDonBan", inputs, new[] { "@MaBill_Out" });
            MessageBox.Show(res.ThongBao);
            if (res.Check) { txtMaBill.Text = res.Outputs["@MaBill_Out"].ToString(); LoadChiTiet(); }
        }

        private void BtnThemMon_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(txtMaBill.Text)) return;
            var inputs = new[] {
                new SqlParameter("@MaBill", txtMaBill.Text),
                new SqlParameter("@MaSP", txtMaSP.Text),
                new SqlParameter("@SoLuong", Convert.ToInt32(txtSoLuong.Text)),
                new SqlParameter("@DonGiaSP", Convert.ToDecimal(txtDonGiaSP.Text))
            };
            var res = DatabaseHelper.ExecuteProc("sp_ThemCTHD_Ban", inputs);
            if (!res.Check) MessageBox.Show(res.ThongBao);
            LoadChiTiet();
        }

        private void BtnHuyMon_Click(object sender, EventArgs e)
        {
            if (dgv.SelectedRows.Count == 0 || string.IsNullOrEmpty(txtMaBill.Text)) return;
            string maSP = dgv.SelectedRows[0].Cells["MaSP"].Value.ToString();
            var res = DatabaseHelper.ExecuteProc("sp_XoaChiTietHoaDonBan", new[] {
                new SqlParameter("@MaBill", txtMaBill.Text), new SqlParameter("@MaSP", maSP)
            });
            MessageBox.Show(res.ThongBao);
            LoadChiTiet();
        }

        private void BtnHuyHD_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(txtMaBill.Text)) return;
            var res = DatabaseHelper.ExecuteProc("sp_XoaHoaDonBan", new[] { new SqlParameter("@MaBill", txtMaBill.Text) });
            MessageBox.Show(res.ThongBao);
            if (res.Check) { txtMaBill.Clear(); txtMSBan.Clear(); dgv.DataSource = null; lblTongTien.Text = "Tổng Tiền: 0 VNĐ"; }
        }

        private void BtnThanhToan_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(txtMaBill.Text)) return;
            // Thực hiện thủ công Update lại bàn về Trống sau khi thanh toán thành công
            string query = $"UPDATE VITRI SET TrangThai = N'Trống' WHERE MSBAN = '{txtMSBan.Text}'";
            DatabaseHelper.GetData(query);
            MessageBox.Show($"Đã thanh toán thành công Bill {txtMaBill.Text}. Bàn đã được dọn!");
            txtMaBill.Clear(); txtMSBan.Clear(); dgv.DataSource = null; lblTongTien.Text = "Tổng Tiền: 0 VNĐ";
        }

        private void LoadChiTiet()
        {
            if (string.IsNullOrEmpty(txtMaBill.Text)) return;
            dgv.DataSource = DatabaseHelper.GetData($"SELECT * FROM CTHD_BAN WHERE MaBILL = '{txtMaBill.Text}'");
            DataTable dtHD = DatabaseHelper.GetData($"SELECT TongTien FROM HOADON_BAN WHERE MaBILL = '{txtMaBill.Text}'");
            if (dtHD.Rows.Count > 0) lblTongTien.Text = $"Tổng Tiền: {dtHD.Rows[0]["TongTien"]:#,##0} VNĐ";
        }
    }
}
