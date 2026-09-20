import unittest
from unittest.mock import patch

import pandas as pd

import report_service


class StaffReportTests(unittest.TestCase):
    def test_appointments_report_handles_record_and_payload_ids(self):
        scheduled = pd.DataFrame(
            [
                {
                    "record_id": "db-1",
                    "record_owner_id": "owner-1",
                    "id": "APT-1",
                    "status": "Completed",
                    "created_at": pd.Timestamp("2026-09-20", tz="UTC"),
                }
            ]
        )
        walk_ins = pd.DataFrame(
            [
                {
                    "record_id": "db-2",
                    "record_owner_id": "owner-2",
                    "id": "WALK-1",
                    "status": "Waiting",
                    "created_at": pd.Timestamp("2026-09-21", tz="UTC"),
                }
            ]
        )

        with patch.object(
            report_service,
            "load_table",
            side_effect=lambda table: scheduled
            if table == "appointments"
            else walk_ins,
        ):
            result = report_service.build_staff_report("appointments")

        self.assertEqual(result["engine"], "python-pandas")
        self.assertEqual(result["metrics"][0]["numeric_value"], 2.0)
        self.assertEqual(result["metrics"][2]["numeric_value"], 1.0)

    def test_queue_report_reads_nested_appointment_priority(self):
        queue = pd.DataFrame(
            [
                {"status": "waiting", "appointment.priority": "Urgent"},
                {"status": "inConsultation", "appointment.priority": "Normal"},
            ]
        )
        with patch.object(report_service, "load_table", return_value=queue):
            result = report_service.build_staff_report("queue")

        metrics = {item["label"]: item for item in result["metrics"]}
        self.assertEqual(metrics["Urgent"]["numeric_value"], 1.0)
        self.assertEqual(metrics["In service"]["numeric_value"], 1.0)


if __name__ == "__main__":
    unittest.main()
