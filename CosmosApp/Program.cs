using System;
using System.Globalization;
using System.IO;
using CsvHelper;
using CsvHelper.Configuration;
using Newtonsoft.Json;
using Npgsql;

namespace CosmosApp
{
    class Program
    {
        static void Main(string[] args)
        {
            var connString = "Host=c-postgre-citus-cluster.exxylgqat2vl6h.postgres.cosmos.azure.com;Port=5432;Username=citus;Password=cPa55w.rd1234;Database=citusdb;SSL Mode=Require;Trust Server Certificate=true;";
            var csvPath = ".\\events.csv"; // Adjust path as needed

            var config = new CsvConfiguration(CultureInfo.InvariantCulture)
            {
                HasHeaderRecord = true,
                TrimOptions = TrimOptions.Trim,
                BadDataFound = null
            };

            using var reader = new StreamReader(csvPath);
            using var csv = new CsvReader(reader, config);
            using var conn = new NpgsqlConnection(connString);
            conn.Open();

            var cmd = new NpgsqlCommand(@"
                INSERT INTO public.payment_events (event_id, event_type, user_id, merchant_id, event_details, created_at)
                VALUES (@event_id, @event_type, @user_id, @merchant_id, @event_details, @created_at)", conn);

            cmd.Parameters.Add(new NpgsqlParameter("@event_id", NpgsqlTypes.NpgsqlDbType.Bigint));
            cmd.Parameters.Add(new NpgsqlParameter("@event_type", NpgsqlTypes.NpgsqlDbType.Text));
            cmd.Parameters.Add(new NpgsqlParameter("@user_id", NpgsqlTypes.NpgsqlDbType.Bigint));
            cmd.Parameters.Add(new NpgsqlParameter("@merchant_id", NpgsqlTypes.NpgsqlDbType.Bigint));
            cmd.Parameters.Add(new NpgsqlParameter("@event_details", NpgsqlTypes.NpgsqlDbType.Jsonb));
            cmd.Parameters.Add(new NpgsqlParameter("@created_at", NpgsqlTypes.NpgsqlDbType.Timestamp));

            var records = csv.GetRecords<dynamic>();
            int success = 0, fail = 0;

            foreach (var r in records)
            {
                try
                {
                    cmd.Parameters["@event_id"].Value = long.Parse(r.event_id);
                    cmd.Parameters["@event_type"].Value = r.event_type;
                    cmd.Parameters["@user_id"].Value = long.Parse(r.user_id);
                    cmd.Parameters["@merchant_id"].Value = long.Parse(r.merchant_id);
                    cmd.Parameters["@event_details"].Value = JsonConvert.SerializeObject(JsonConvert.DeserializeObject(r.event_details));
                    cmd.Parameters["@created_at"].Value = DateTime.Parse(r.created_at);

                    cmd.ExecuteNonQuery();
                    Console.WriteLine($"Inserted {r.event_id}");
                    success++;
                }
                catch (Exception ex)
                {
                    fail++;
                    Console.WriteLine($"❌ Skipped record: {ex.Message}");
                }
            }

            Console.WriteLine($"\n✅ Imported: {success} rows, ❌ Failed: {fail}");
        }
    }
}
