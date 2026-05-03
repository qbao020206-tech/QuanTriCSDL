using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace CongCafe
{
    public partial class MainForm : Form
    {
        public MainForm()
        {
            Text = $"Hệ Thống Quản Lý Cà Phê - User: {GlobalState.Username}";
            WindowState = FormWindowState.Maximized;
            IsMdiContainer = true;

            MenuStrip menu = new MenuStrip();

            // Ép màu cho thanh Menu chính
            menu.BackColor = ThemeHelper.CongGreen;
            menu.ForeColor = Color.White;
            menu.Font = new Font("Segoe UI", 10F, FontStyle.Bold);
            menu.Padding = new Padding(10);

            ToolStripMenuItem menuKhachHang = new ToolStripMenuItem("Khách Hàng", null, (s, e) => OpenForm(new KhachHangForm()));
            ToolStripMenuItem menuBanHang = new ToolStripMenuItem("Bán Hàng", null, (s, e) => OpenForm(new BanHangForm()));
            ToolStripMenuItem menuThongKe = new ToolStripMenuItem("Thống Kê", null, (s, e) => OpenForm(new ThongKeForm()));
            ToolStripMenuItem menuSanPham = new ToolStripMenuItem("Sản Phẩm", null, (s, e) => OpenForm(new SanPhamForm()));

            menu.Items.AddRange(new ToolStripItem[] { menuKhachHang, menuBanHang, menuSanPham, menuThongKe });

            // Phân quyền Manager
            if (GlobalState.IsManager)
            {
                ToolStripMenuItem menuNhapHang = new ToolStripMenuItem("Nhập Hàng", null, (s, e) => OpenForm(new NhapHangForm()));
                ToolStripMenuItem menuNVL = new ToolStripMenuItem("Nguyên Vật Liệu", null, (s, e) => OpenForm(new NVLForm()));
                ToolStripMenuItem menuNCC = new ToolStripMenuItem("Nhà Cung Cấp", null, (s, e) => OpenForm(new NCCForm()));
                ToolStripMenuItem menuNhanVien = new ToolStripMenuItem("Nhân Viên", null, (s, e) => OpenForm(new NhanVienForm()));

                menu.Items.Add(menuNhapHang);
                menu.Items.Add(menuNVL);
                menu.Items.Add(menuNCC);
                menu.Items.Add(menuNhanVien);
            }

            ToolStripMenuItem menuThoat = new ToolStripMenuItem("Thoát", null, (s, e) => Application.Exit());
            menu.Items.Add(menuThoat);

            Controls.Add(menu);
            MainMenuStrip = menu;

            // Đổi màu nền của MainForm
            ThemeHelper.ApplyTheme(this);
        }

        private void OpenForm(Form childForm)
        {
            foreach (Form f in MdiChildren) f.Close();
            childForm.MdiParent = this;
            childForm.Dock = DockStyle.Fill;
            childForm.Show();
        }
    }
}
