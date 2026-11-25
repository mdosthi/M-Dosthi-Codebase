"""
examples/test_compute_delta_real.py
------------------------------------
Ad-hoc test of _compute_delta() using real trigger/concern data pulled from
the M-Dosthi_merged database for patient VBCR0192706250000.

Session pair used (2025-07-10, two consecutive chats):
  prev (chat_b99ff528): triggers = ["today", "after eating food", "drinking chai", "relaxation"]
  curr (chat_8ab45812):  triggers = ["feeling down"]

  prev (chat_ffb7d77c): concerns = ["cravings", "missing out on cravings"]
  curr (chat_51fa6b54):  concerns = ["smoking as a comfort when alone", "craving for cigarettes when alone"]

Usage:
    python -m examples.test_compute_delta_real
"""
import sys
from pathlib import Path

_PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJECT_ROOT))

from annotate.agents.longitudinal.delta_agent import _compute_delta


def main():
    print("=== Trigger delta ===")
    new, persistent, resolved = _compute_delta(
        signal_type="trigger",
        prev=["today", "after eating food", "drinking chai", "relaxation"],
        curr=["feeling down"],
        transcript="",
    )
    print(f"new:        {new}")
    print(f"persistent: {persistent}")
    print(f"resolved:   {resolved}")

    print("\n=== Concern delta ===")
    new, persistent, resolved = _compute_delta(
        signal_type="concern",
        prev=["cravings", "missing out on cravings"],
        curr=["smoking as a comfort when alone", "craving for cigarettes when alone"],
        transcript="",
    )
    print(f"new:        {new}")
    print(f"persistent: {persistent}")
    print(f"resolved:   {resolved}")


if __name__ == "__main__":
    main()
