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
    public partial class NhanVienForm : Form
    {
        DataGridView dgv;
        TextBox txtMaNV, txtTenNV, txtSTK, txtSDT;
        ComboBox cbGioiTinh;
        DateTimePicker dtpNgaySinh;
        private int currentPage = 1;
        private int pageSize = 10;
        private Label lblPageInfo;

        public NhanVienForm()
        {
            Text = "Quản Lý Nhân Viên";
            FormBorderStyle = FormBorderStyle.None;
            SetupUI();
            LoadData();

            ThemeHelper.ApplyTheme(this);
        }

        private void SetupUI()
        {
            Panel pnlTop = new Panel() { Height = 220, Dock = DockStyle.Top };

            pnlTop.Controls.Add(new Label() { Text = "Mã NV:", Location = new Point(20, 20), AutoSize = true });
            txtMaNV = new TextBox() { Location = new Point(100, 20), Width = 150 };

            pnlTop.Controls.Add(new Label() { Text = "Giới Tính:", Location = new Point(280, 20), AutoSize = true });
            cbGioiTinh = new ComboBox() { Location = new Point(370, 20), Width = 150, DropDownStyle = ComboBoxStyle.DropDownList };
            cbGioiTinh.Items.AddRange(new[] { "Nam", "Nữ" });

            Button btnThem = new Button() { Text = "Thêm", Location = new Point(560, 18), Width = 100 };
            btnThem.Click += BtnThem_Click;

            pnlTop.Controls.Add(new Label() { Text = "Tên NV:", Location = new Point(20, 70), AutoSize = true });
            txtTenNV = new TextBox() { Location = new Point(100, 70), Width = 150 };

            pnlTop.Controls.Add(new Label() { Text = "Ngày Sinh:", Location = new Point(280, 70), AutoSize = true });
            dtpNgaySinh = new DateTimePicker() { Location = new Point(370, 70), Format = DateTimePickerFormat.Short, Width = 150 };

            Button btnSua = new Button() { Text = "Sửa", Location = new Point(560, 68), Width = 100 };
            btnSua.Click += BtnSua_Click;

            pnlTop.Controls.Add(new Label() { Text = "STK:", Location = new Point(20, 120), AutoSize = true });
            txtSTK = new TextBox() { Location = new Point(100, 120), Width = 150 };

            pnlTop.Controls.Add(new Label() { Text = "SĐT:", Location = new Point(280, 120), AutoSize = true });
            txtSDT = new TextBox() { Location = new Point(370, 120), Width = 150 };

            Button btnXoa = new Button() { Text = "Xóa", Location = new Point(560, 118), Width = 100 };
            btnXoa.Click += BtnXoa_Click;

            Button btnPrev = new Button() { Text = "< Trước", Location = new Point(20, 165), Width = 80 };
            btnPrev.Click += (s, e) => { if (currentPage > 1) { currentPage--; LoadData(); } };

            Button btnNext = new Button() { Text = "Tiếp >", Location = new Point(110, 165), Width = 80 };
            btnNext.Click += (s, e) => { currentPage++; LoadData(); };

            lblPageInfo = new Label() { Location = new Point(200, 170), AutoSize = true, Text = "Trang 1" };

            pnlTop.Controls.AddRange(new Control[] { txtMaNV, txtTenNV, cbGioiTinh, dtpNgaySinh, txtSTK, txtSDT,
                btnThem, btnSua, btnXoa, btnPrev, btnNext, lblPageInfo });

            dgv = new DataGridView() { Dock = DockStyle.Fill, AllowUserToAddRows = false, ReadOnly = true, SelectionMode = DataGridViewSelectionMode.FullRowSelect };
            dgv.CellClick += (s, e) => {
                if (e.RowIndex >= 0)
                {
                    DataGridViewRow r = dgv.Rows[e.RowIndex];
                    txtMaNV.Text = r.Cells["MaNV"].Value.ToString();
                    txtTenNV.Text = r.Cells["TenNV"].Value.ToString();
                    cbGioiTinh.Text = r.Cells["GioiTinh"].Value.ToString();
                    dtpNgaySinh.Value = Convert.ToDateTime(r.Cells["NgaySinhNV"].Value);
                    txtSTK.Text = r.Cells["STK"].Value.ToString();
                    txtSDT.Text = r.Cells["SDTNV"].Value.ToString();
                }
            };

            Controls.Add(dgv);
            Controls.Add(pnlTop);
        }

        private void LoadData()
        {
            string query = $"SELECT * FROM NHANVIEN ORDER BY MaNV OFFSET {(currentPage - 1) * pageSize} ROWS FETCH NEXT {pageSize} ROWS ONLY";
            dgv.DataSource = DatabaseHelper.GetData(query);
            int totalRecords = PaginationHelper.GetTotalRecords("NHANVIEN");
            int totalPages = (int)Math.Ceiling((double)totalRecords / pageSize);
            lblPageInfo.Text = $"Trang {currentPage}/{totalPages} ({totalRecords} nhân viên)";
            if (currentPage >= totalPages) currentPage = totalPages;
        }

        private void BtnThem_Click(object sender, EventArgs e)
        {
            var res = DatabaseHelper.ExecuteProc("sp_ThemNhanVien", new[] {
                new SqlParameter("@MaNV", txtMaNV.Text),
                new SqlParameter("@TenNV", txtTenNV.Text),
                new SqlParameter("@GioiTinh", cbGioiTinh.Text),
                new SqlParameter("@NgaySinhNV", dtpNgaySinh.Value),
                new SqlParameter("@STK", txtSTK.Text),
                new SqlParameter("@SDTNV", txtSDT.Text)
            });
            MessageBox.Show(res.ThongBao);
            if (res.Check) LoadData();
        }

        private void BtnSua_Click(object sender, EventArgs e)
        {
            var res = DatabaseHelper.ExecuteProc("sp_SuaNhanVien", new[] {
                new SqlParameter("@MaNV", txtMaNV.Text),
                new SqlParameter("@TenNV", txtTenNV.Text),
                new SqlParameter("@GioiTinh", cbGioiTinh.Text),
                new SqlParameter("@NgaySinhNV", dtpNgaySinh.Value),
                new SqlParameter("@STK", txtSTK.Text),
                new SqlParameter("@SDTNV", txtSDT.Text)
            });
            MessageBox.Show(res.ThongBao);
            if (res.Check) LoadData();
        }

        private void BtnXoa_Click(object sender, EventArgs e)
        {
            var res = DatabaseHelper.ExecuteProc("sp_XoaNhanVien", new[] { new SqlParameter("@MaNV", txtMaNV.Text) });
            MessageBox.Show(res.ThongBao);
            if (res.Check) LoadData();
        }
    }
}
