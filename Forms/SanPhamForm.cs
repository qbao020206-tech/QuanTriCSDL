using System;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Windows.Forms;

namespace CongCafe
{
    public partial class SanPhamForm : Form
    {
        DataGridView dgv;
        TextBox txtMaSP, txtTenSP, txtGiaSP;
        ComboBox cbMaLSP;

        public SanPhamForm()
        {
            Text = "Quản Lý Sản Phẩm";
            FormBorderStyle = FormBorderStyle.None;
            SetupUI();
            LoadLoaiSanPham();
            LoadData();

            ThemeHelper.ApplyTheme(this);
        }

        private void SetupUI()
        {
            Panel pnlTop = new Panel() { Height = 130, Dock = DockStyle.Top };

            // Dòng 1 (Y=20)
            pnlTop.Controls.Add(new Label() { Text = "Mã SP:", Location = new Point(20, 20), AutoSize = true });
            txtMaSP = new TextBox() { Location = new Point(90, 20), Width = 150 };

            pnlTop.Controls.Add(new Label() { Text = "Giá Bán:", Location = new Point(280, 20), AutoSize = true });
            txtGiaSP = new TextBox() { Location = new Point(360, 20), Width = 150 };

            Button btnThem = new Button() { Text = "Thêm", Location = new Point(560, 18), Width = 100 };
            btnThem.Click += BtnThem_Click;

            Button btnXoa = new Button() { Text = "Xóa", Location = new Point(680, 18), Width = 100, Enabled = GlobalState.IsManager };
            btnXoa.Click += BtnXoa_Click;

            // Dòng 2 (Y=70)
            pnlTop.Controls.Add(new Label() { Text = "Tên SP:", Location = new Point(20, 70), AutoSize = true });
            txtTenSP = new TextBox() { Location = new Point(90, 70), Width = 150 };

            pnlTop.Controls.Add(new Label() { Text = "Mã Loại:", Location = new Point(280, 70), AutoSize = true });
            cbMaLSP = new ComboBox() { Location = new Point(360, 70), Width = 150, DropDownStyle = ComboBoxStyle.DropDownList };

            Button btnSua = new Button() { Text = "Sửa", Location = new Point(560, 68), Width = 100 };
            btnSua.Click += BtnSua_Click;

            pnlTop.Controls.AddRange(new Control[] { txtMaSP, txtTenSP, txtGiaSP, cbMaLSP, btnThem, btnSua, btnXoa });

            dgv = new DataGridView() { Dock = DockStyle.Fill, AllowUserToAddRows = false, ReadOnly = true, SelectionMode = DataGridViewSelectionMode.FullRowSelect };
            dgv.CellClick += Dgv_CellClick;

            Controls.Add(dgv);
            Controls.Add(pnlTop);
        }

        private void LoadLoaiSanPham()
        {
            DataTable dt = DatabaseHelper.GetData("SELECT MaLSP, TenLSP FROM LOAISANPHAM");
            cbMaLSP.DataSource = dt;
            cbMaLSP.DisplayMember = "TenLSP";
            cbMaLSP.ValueMember = "MaLSP";
        }

        private void LoadData() => dgv.DataSource = DatabaseHelper.GetData("SELECT * FROM SANPHAM");

        private void Dgv_CellClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex >= 0)
            {
                DataGridViewRow r = dgv.Rows[e.RowIndex];
                txtMaSP.Text = r.Cells["MaSP"].Value.ToString();
                txtTenSP.Text = r.Cells["TenSP"].Value.ToString();
                txtGiaSP.Text = Convert.ToDecimal(r.Cells["GiaSP"].Value).ToString("0");
                cbMaLSP.SelectedValue = r.Cells["MaLSP"].Value.ToString();
            }
        }

        private void BtnThem_Click(object sender, EventArgs e)
        {
            var inputs = new[] {
                new SqlParameter("@MaSP", txtMaSP.Text),
                new SqlParameter("@TenSP", txtTenSP.Text),
                new SqlParameter("@GiaSP", Convert.ToDecimal(txtGiaSP.Text)),
                new SqlParameter("@MaLSP", cbMaLSP.SelectedValue.ToString())
            };
            var res = DatabaseHelper.ExecuteProc("sp_ThemSanPham", inputs);
            MessageBox.Show(res.ThongBao);
            if(res.Check) LoadData();
        }

        private void BtnSua_Click(object sender, EventArgs e)
        {
            var inputs = new[] {
                new SqlParameter("@MaSP", txtMaSP.Text),
                new SqlParameter("@TenSP", txtTenSP.Text),
                new SqlParameter("@GiaSP", Convert.ToDecimal(txtGiaSP.Text)),
                new SqlParameter("@MaLSP", cbMaLSP.SelectedValue.ToString())
            };
            var res = DatabaseHelper.ExecuteProc("sp_SuaSanPham", inputs);
            MessageBox.Show(res.ThongBao);
            if(res.Check) LoadData();
        }

        private void BtnXoa_Click(object sender, EventArgs e)
        {
            var res = DatabaseHelper.ExecuteProc("sp_XoaSanPham", new[] { new SqlParameter("@MaSP", txtMaSP.Text) });
            MessageBox.Show(res.ThongBao);
            if(res.Check) LoadData();
        }
    }
}