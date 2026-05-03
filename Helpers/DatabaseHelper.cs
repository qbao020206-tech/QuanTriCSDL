using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Windows.Forms;

namespace CongCafe
{
    public static class GlobalState
    {
        public static string Server = "localhost"; // Nếu máy bạn dùng SQLEXPRESS, hãy đổi thành "localhost\\SQLEXPRESS"
        public static string Database = "QLY_CONGCAFFE";

        public static string Username { get; set; }
        public static string Password { get; set; }
        public static bool IsManager => Username?.ToLower() == "store_manager";

        public static string GetConnectionString()
        {
            return $"Server={Server};Database={Database};User Id={Username};Password={Password};";
        }
    }

    public class DbResult
    {
        public bool Check { get; set; }
        public string ThongBao { get; set; }
        public Dictionary<string, object> Outputs { get; set; } = new Dictionary<string, object>();
    }

    public static class DatabaseHelper
    {
        public static DataTable GetData(string query)
        {
            DataTable dt = new DataTable();
            try
            {
                using (SqlConnection conn = new SqlConnection(GlobalState.GetConnectionString()))
                {
                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }
            catch (Exception ex) { MessageBox.Show("Lỗi lấy dữ liệu: " + ex.Message); }
            return dt;
        }

        public static DbResult ExecuteProc(string procName, SqlParameter[] inputs, string[] outputNames = null)
        {
            DbResult result = new DbResult();
            try
            {
                using (SqlConnection conn = new SqlConnection(GlobalState.GetConnectionString()))
                {
                    using (SqlCommand cmd = new SqlCommand(procName, conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        if (inputs != null) cmd.Parameters.AddRange(inputs);

                        // Mặc định luôn có @thongBao và @check
                        SqlParameter pThongBao = new SqlParameter("@thongBao", SqlDbType.NVarChar, 500) { Direction = ParameterDirection.Output };
                        SqlParameter pCheck = new SqlParameter("@check", SqlDbType.Bit) { Direction = ParameterDirection.Output };
                        cmd.Parameters.Add(pThongBao);
                        cmd.Parameters.Add(pCheck);

                        // Thêm các param output tuỳ chọn khác (ví dụ: @MaHD_NH_Out)
                        if (outputNames != null)
                        {
                            foreach (var outName in outputNames)
                            {
                                cmd.Parameters.Add(new SqlParameter(outName, SqlDbType.VarChar, 20) { Direction = ParameterDirection.Output });
                            }
                        }

                        conn.Open();
                        cmd.ExecuteNonQuery();

                        result.Check = pCheck.Value != DBNull.Value && Convert.ToBoolean(pCheck.Value);
                        result.ThongBao = pThongBao.Value?.ToString() ?? "";

                        if (outputNames != null)
                        {
                            foreach (var outName in outputNames)
                                result.Outputs[outName] = cmd.Parameters[outName].Value;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                result.Check = false;
                result.ThongBao = "Lỗi thực thi: " + ex.Message;
            }
            return result;
        }
    }
}