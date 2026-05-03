using System;
using System.Data;
using System.Data.SqlClient;

namespace CongCafe
{
    public class PaginationHelper
    {
        public static DataTable GetPagedData(string tableName, int pageNumber, int pageSize, string orderByColumn = "1")
        {
            int offset = (pageNumber - 1) * pageSize;
            string query = $"SELECT * FROM {tableName} ORDER BY {orderByColumn} OFFSET {offset} ROWS FETCH NEXT {pageSize} ROWS ONLY";
            return DatabaseHelper.GetData(query);
        }

        public static int GetTotalRecords(string tableName)
        {
            string query = $"SELECT COUNT(*) FROM {tableName}";
            DataTable dt = DatabaseHelper.GetData(query);
            if (dt.Rows.Count > 0)
                return Convert.ToInt32(dt.Rows[0][0]);
            return 0;
        }

        public static int GetTotalPages(string tableName, int pageSize)
        {
            int total = GetTotalRecords(tableName);
            return (int)Math.Ceiling((double)total / pageSize);
        }
    }
}
