"""I compute KPIs from the cleaned data and save 3 charts (no hardcoded numbers)."""
import os
import sqlite3
import pandas as pd
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

BASE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(BASE, "service-requests.db")
CLEAN_CSV = os.path.join(BASE, "data_clean", "requests_clean.csv")
CHARTS = os.path.join(BASE, "charts")

# I style every chart from the vision tokens (see design/ui/UI-DESIGN.md).
FIGSIZE = (12, 6.75)
DPI = 150
BG = "#F6F8FA"
CARD = "#FFFFFF"
INK = "#1B2A3A"
MUTED = "#5B6B7A"
GRID = "#E2E8F0"
ACCENT = "#2563EB"
PRIO_COLORS = {
    "Low": "#94A3B8",
    "Medium": "#38BDF8",
    "High": "#F59E0B",
    "Critical": "#DC2626",
}
PRIO_ORDER = ["Low", "Medium", "High", "Critical"]

plt.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Segoe UI", "Inter", "DejaVu Sans"],
    "axes.titlesize": 15,
    "axes.titleweight": "semibold",
})


def load_clean():
    # I prefer the Tableau-ready CSV; I fall back to SQLite if it is missing.
    if os.path.exists(CLEAN_CSV):
        return pd.read_csv(CLEAN_CSV)
    con = sqlite3.connect(DB)
    try:
        return pd.read_sql_query("SELECT * FROM requests_clean", con)
    finally:
        con.close()


def new_fig():
    # I build every figure at the shared 12x6.75in size on the app background.
    fig, ax = plt.subplots(figsize=FIGSIZE)
    fig.patch.set_facecolor(BG)
    return fig, ax


def style_ax(ax, title, xlabel, ylabel):
    # I keep the card look: white axes on app bg, y-grid only, no top/right spines.
    ax.set_facecolor(CARD)
    ax.set_title(title, color=INK, loc="left", pad=12)
    ax.set_xlabel(xlabel, fontsize=10.5, color=MUTED)
    ax.set_ylabel(ylabel, fontsize=10.5, color=MUTED)
    ax.tick_params(colors=MUTED, labelsize=10.5)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color(GRID)
    ax.spines["bottom"].set_color(GRID)
    ax.yaxis.grid(True, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)


def main():
    os.makedirs(CHARTS, exist_ok=True)
    df = load_clean()

    # I derive every number below from df — nothing hardcoded.
    monthly = df[df["created_month"].notna()].groupby("created_month").size().sort_index()
    top_types = df["request_type"].value_counts().head(8).sort_values(ascending=False)
    res = df[(df["resolution_days"].notna()) & (df["resolution_days"] >= 0)]
    avg_prio = res.groupby("priority")["resolution_days"].mean().reindex(
        PRIO_ORDER
    ).dropna()

    # 1. I plot the monthly volume line with peak/valley callouts.
    fig, ax = new_fig()
    ax.plot(monthly.index, monthly.values, color=ACCENT, linewidth=2.5,
            marker="o", markersize=6, markerfacecolor=ACCENT,
            markeredgecolor=CARD, markeredgewidth=1.4)
    style_ax(ax, "Service requests \u2014 monthly volume", "Month", "Requests")
    peak_m, peak_v = monthly.idxmax(), int(monthly.max())
    low_m, low_v = monthly.idxmin(), int(monthly.min())
    # I call out the peak and the valley so the trend reads at a glance.
    ax.annotate(f"Peak {peak_m}: {peak_v}", xy=(peak_m, peak_v),
                xytext=(0, 16), textcoords="offset points", ha="center",
                fontsize=10, fontweight="semibold", color=INK,
                arrowprops=dict(arrowstyle="->", color=MUTED))
    ax.annotate(f"Low {low_m}: {low_v}", xy=(low_m, low_v),
                xytext=(0, -22), textcoords="offset points", ha="center",
                fontsize=10, fontweight="semibold", color=INK,
                arrowprops=dict(arrowstyle="->", color=MUTED))
    plt.setp(ax.get_xticklabels(), rotation=45, ha="right")
    fig.tight_layout()
    fig.savefig(os.path.join(CHARTS, "monthly_volume.png"), dpi=DPI, facecolor=BG)
    plt.close(fig)

    # 2. I plot the top request types bar, sorted desc.
    fig, ax = new_fig()
    bars = ax.bar(top_types.index, top_types.values, color=ACCENT,
                  edgecolor=CARD, linewidth=0.8)
    style_ax(ax, "Service requests \u2014 top request types", "Request type", "Requests")
    # I put white value labels inside each bar so counts read without the axis.
    ax.bar_label(bars, labels=[str(int(v)) for v in top_types.values],
                label_type="center", color="white", fontsize=10, fontweight="semibold")
    plt.setp(ax.get_xticklabels(), rotation=25, ha="right")
    fig.tight_layout()
    fig.savefig(os.path.join(CHARTS, "top_request_types.png"), dpi=DPI, facecolor=BG)
    plt.close(fig)

    # 3. I plot avg resolution days by priority in Low-to-Critical order.
    fig, ax = new_fig()
    colors = [PRIO_COLORS[p] for p in avg_prio.index]
    bars = ax.bar(avg_prio.index, avg_prio.values, color=colors,
                  edgecolor=CARD, linewidth=0.8)
    style_ax(ax, "Average resolution days by priority", "Priority", "Avg days")
    # I label each bar in white so the averages read directly on the colors.
    ax.bar_label(bars, labels=[f"{v:.1f}" for v in avg_prio.values],
                 label_type="center", color="white", fontsize=10, fontweight="semibold")
    fig.tight_layout()
    fig.savefig(os.path.join(CHARTS, "avg_resolution_by_priority.png"), dpi=DPI, facecolor=BG)
    plt.close(fig)

    total = len(df)
    closed = int((df["status"] == "Closed").sum())
    open_rate = 100.0 * float((df["status"].isin(["Open", "In Progress"])).sum()) / total
    print(f"rows={total} closed={closed} backlog_pct={open_rate:.1f}")
    print(f"top_type={top_types.index[0]} ({int(top_types.iloc[0])})")
    print("charts: monthly_volume.png, top_request_types.png, avg_resolution_by_priority.png")


if __name__ == "__main__":
    main()
