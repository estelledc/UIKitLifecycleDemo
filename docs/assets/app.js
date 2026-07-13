const categoryNames = [
  "Lifecycle",
  "Layout",
  "List",
  "Detail",
  "NavStack",
  "DataSource",
  "Snapshot",
  "Cell",
  "Delegate",
  "Action",
  "Closure",
  "Memory",
  "Guide",
  "General",
];

const list = document.querySelector("#category-list");
const input = document.querySelector("#category-filter");
const count = document.querySelector("#category-count");

function renderCategories(query = "") {
  const normalized = query.trim().toLocaleLowerCase();
  const matches = categoryNames.filter((name) => name.toLocaleLowerCase().includes(normalized));
  list.replaceChildren(...matches.map((name) => {
    const chip = document.createElement("span");
    chip.className = "category-chip";
    chip.textContent = name;
    return chip;
  }));
  count.textContent = `${matches.length} / ${categoryNames.length} categories`;
}

input.addEventListener("input", () => renderCategories(input.value));
renderCategories();
