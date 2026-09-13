/**
 * Nested Sub-Types Tests
 * Tests the nested sub-type hierarchy for codex tree
 */

// Minimal test harness
let passed = 0;
let failed = 0;
function assert(condition, label) {
  if (condition) {
    console.log("PASS:", label);
    passed++;
  } else {
    console.error("FAIL:", label);
    failed++;
  }
}

console.log("=== Nested Sub-Types Tests ===\n");

// Test 1: Parse nested sub-types from tree definition
console.log("--- Parse Nested Sub-Types ---");

// Simulate the tree definition with nested sub-types
var treeDef = [
  {
    category: "CORE",
    items: [
      {
        key: "species",
        label: "Species",
        entityTypeKey: "species",
        subTypes: [
          {
            key: "humanoid",
            label: "Humanoid",
            subTypes: [
              {
                key: "elf",
                label: "Elf",
                subTypes: ["Green Elf", "High Elf", "Dark Elf"]
              },
              {
                key: "dwarf",
                label: "Dwarf",
                subTypes: ["Mountain Dwarf", "Hill Dwarf"]
              },
              { key: "human", label: "Human" }
            ]
          },
          { key: "beast", label: "Beast" },
          { key: "plant", label: "Plant" }
        ]
      }
    ]
  }
];

// Test 2: Flatten nested sub-types into a list for dropdown
console.log("\n--- Flatten Nested Sub-Types ---");

function flattenSubTypes(subTypes, prefix) {
  prefix = prefix || "";
  var result = [];
  if (!Array.isArray(subTypes)) return result;
  
  subTypes.forEach(function(st) {
    var label = typeof st === 'string' ? st : (st.label || st.key || "");
    var key = typeof st === 'string' ? st.toLowerCase().replace(/\s+/g, '_') : (st.key || st.label || "").toLowerCase().replace(/\s+/g, '_');
    var fullLabel = prefix ? prefix + " > " + label : label;
    var depth = prefix ? prefix.split(" > ").length : 0;
    
    result.push({ key: key, label: label, fullLabel: fullLabel, depth: depth });
    
    // Recursively add nested sub-types
    if (typeof st === 'object' && st.subTypes && st.subTypes.length > 0) {
      var nested = flattenSubTypes(st.subTypes, fullLabel);
      result = result.concat(nested);
    }
  });
  
  return result;
}

var speciesItem = treeDef[0].items[0];
var flatList = flattenSubTypes(speciesItem.subTypes);

assert(flatList.length > 0, "Should have flattened sub-types");
assert(flatList[0].label === "Humanoid", "First item should be Humanoid");
assert(flatList[0].fullLabel === "Humanoid", "First item fullLabel should be Humanoid");
assert(flatList[0].depth === 0, "First item depth should be 0");

// Find Elf in the list
var elfItem = flatList.find(function(item) { return item.label === "Elf"; });
assert(elfItem !== undefined, "Should find Elf in flattened list");
assert(elfItem.fullLabel === "Humanoid > Elf", "Elf fullLabel should be 'Humanoid > Elf'");
assert(elfItem.depth === 1, "Elf depth should be 1");

// Find Green Elf in the list
var greenElfItem = flatList.find(function(item) { return item.label === "Green Elf"; });
assert(greenElfItem !== undefined, "Should find Green Elf in flattened list");
assert(greenElfItem.fullLabel === "Humanoid > Elf > Green Elf", "Green Elf fullLabel should be 'Humanoid > Elf > Green Elf'");
assert(greenElfItem.depth === 2, "Green Elf depth should be 2");

// Test 3: Match entity to sub-type hierarchy
console.log("\n--- Match Entity to Sub-Type Hierarchy ---");

function matchEntityToSubType(entity, subTypes) {
  var subType = entity.custom_data && entity.custom_data.sub_type ? entity.custom_data.sub_type : "";
  if (!subType) return null;
  
  // Try to match against flattened sub-types
  var flatList = flattenSubTypes(subTypes);
  var match = flatList.find(function(item) {
    return item.label.toLowerCase() === subType.toLowerCase() || 
           item.fullLabel.toLowerCase() === subType.toLowerCase();
  });
  
  return match ? match.fullLabel : subType;
}

// Test entity with sub_type = "Elf"
var entity1 = { custom_data: { sub_type: "Elf" } };
var match1 = matchEntityToSubType(entity1, speciesItem.subTypes);
assert(match1 === "Humanoid > Elf", "Entity with sub_type 'Elf' should match 'Humanoid > Elf'");

// Test entity with sub_type = "Green Elf"
var entity2 = { custom_data: { sub_type: "Green Elf" } };
var match2 = matchEntityToSubType(entity2, speciesItem.subTypes);
assert(match2 === "Humanoid > Elf > Green Elf", "Entity with sub_type 'Green Elf' should match 'Humanoid > Elf > Green Elf'");

// Test entity with sub_type = "Humanoid"
var entity3 = { custom_data: { sub_type: "Humanoid" } };
var match3 = matchEntityToSubType(entity3, speciesItem.subTypes);
assert(match3 === "Humanoid", "Entity with sub_type 'Humanoid' should match 'Humanoid'");

// Test entity with sub_type = "Beast"
var entity4 = { custom_data: { sub_type: "Beast" } };
var match4 = matchEntityToSubType(entity4, speciesItem.subTypes);
assert(match4 === "Beast", "Entity with sub_type 'Beast' should match 'Beast'");

// Test 4: Build dropdown options with hierarchy
console.log("\n--- Build Dropdown Options ---");

function buildSubTypeDropdownOptions(subTypes, prefix, depth) {
  prefix = prefix || "";
  depth = depth || 0;
  var options = [];
  
  if (!Array.isArray(subTypes)) return options;
  
  subTypes.forEach(function(st) {
    var label = typeof st === 'string' ? st : (st.label || st.key || "");
    var indent = "  ".repeat(depth);
    var optionLabel = indent + label;
    
    options.push({ value: label, label: optionLabel, depth: depth });
    
    // Recursively add nested sub-types
    if (typeof st === 'object' && st.subTypes && st.subTypes.length > 0) {
      var nested = buildSubTypeDropdownOptions(st.subTypes, label, depth + 1);
      options = options.concat(nested);
    }
  });
  
  return options;
}

var dropdownOptions = buildSubTypeDropdownOptions(speciesItem.subTypes);
assert(dropdownOptions.length > 0, "Should have dropdown options");
assert(dropdownOptions[0].value === "Humanoid", "First option should be Humanoid");
assert(dropdownOptions[0].depth === 0, "First option depth should be 0");

// Find Elf option
var elfOption = dropdownOptions.find(function(opt) { return opt.value === "Elf"; });
assert(elfOption !== undefined, "Should find Elf option");
assert(elfOption.depth === 1, "Elf option depth should be 1");
assert(elfOption.label.startsWith("  "), "Elf option should be indented");

// Find Green Elf option
var greenElfOption = dropdownOptions.find(function(opt) { return opt.value === "Green Elf"; });
assert(greenElfOption !== undefined, "Should find Green Elf option");
assert(greenElfOption.depth === 2, "Green Elf option depth should be 2");
assert(greenElfOption.label.startsWith("    "), "Green Elf option should be double-indented");

// Test 5: Entity custom_data with nested sub_type
console.log("\n--- Entity Custom Data ---");

// Test storing nested sub-type as array
var entityWithNested = {
  custom_data: {
    sub_type: "Elf",
    sub_type_hierarchy: ["Humanoid", "Elf", "Green Elf"]
  }
};

assert(Array.isArray(entityWithNested.custom_data.sub_type_hierarchy), "sub_type_hierarchy should be array");
assert(entityWithNested.custom_data.sub_type_hierarchy.length === 3, "sub_type_hierarchy should have 3 levels");
assert(entityWithNested.custom_data.sub_type_hierarchy[0] === "Humanoid", "First level should be Humanoid");
assert(entityWithNested.custom_data.sub_type_hierarchy[1] === "Elf", "Second level should be Elf");
assert(entityWithNested.custom_data.sub_type_hierarchy[2] === "Green Elf", "Third level should be Green Elf");

// Test 6: Build breadcrumb from hierarchy
console.log("\n--- Build Breadcrumb ---");

function buildSubTypeBreadcrumb(subTypeHierarchy) {
  if (!Array.isArray(subTypeHierarchy) || subTypeHierarchy.length === 0) return "";
  return subTypeHierarchy.join(" > ");
}

var breadcrumb = buildSubTypeBreadcrumb(entityWithNested.custom_data.sub_type_hierarchy);
assert(breadcrumb === "Humanoid > Elf > Green Elf", "Breadcrumb should be 'Humanoid > Elf > Green Elf'");

// Test 7: Get leaf sub-type (deepest level)
console.log("\n--- Get Leaf Sub-Type ---");

function getLeafSubType(subTypeHierarchy, subType) {
  if (Array.isArray(subTypeHierarchy) && subTypeHierarchy.length > 0) {
    return subTypeHierarchy[subTypeHierarchy.length - 1];
  }
  return subType || "";
}

var leafType = getLeafSubType(entityWithNested.custom_data.sub_type_hierarchy, entityWithNested.custom_data.sub_type);
assert(leafType === "Green Elf", "Leaf sub-type should be 'Green Elf'");

var leafType2 = getLeafSubType([], "Elf");
assert(leafType2 === "Elf", "Leaf sub-type from flat sub_type should be 'Elf'");

// Test 8: Filter entities by sub-type level
console.log("\n--- Filter Entities by Sub-Type Level ---");

function filterEntitiesBySubTypeLevel(entities, level, value) {
  return entities.filter(function(e) {
    var hierarchy = e.custom_data && e.custom_data.sub_type_hierarchy ? e.custom_data.sub_type_hierarchy : [];
    if (level >= hierarchy.length) return false;
    return hierarchy[level].toLowerCase() === value.toLowerCase();
  });
}

var entities = [
  { name: "Elf 1", custom_data: { sub_type_hierarchy: ["Humanoid", "Elf", "Green Elf"] } },
  { name: "Elf 2", custom_data: { sub_type_hierarchy: ["Humanoid", "Elf", "High Elf"] } },
  { name: "Dwarf 1", custom_data: { sub_type_hierarchy: ["Humanoid", "Dwarf", "Mountain Dwarf"] } },
  { name: "Human 1", custom_data: { sub_type_hierarchy: ["Humanoid", "Human"] } }
];

var humanoids = filterEntitiesBySubTypeLevel(entities, 0, "Humanoid");
assert(humanoids.length === 4, "Should find 4 humanoids");

var elves = filterEntitiesBySubTypeLevel(entities, 1, "Elf");
assert(elves.length === 2, "Should find 2 elves");

var greenElves = filterEntitiesBySubTypeLevel(entities, 2, "Green Elf");
assert(greenElves.length === 1, "Should find 1 green elf");
assert(greenElves[0].name === "Elf 1", "Green elf should be Elf 1");

// Results
console.log("\n=== Results ===");
console.log("Passed:", passed);
console.log("Failed:", failed);
console.log("Total:", passed + failed);

if (failed > 0) {
  console.error("\nFAIL — " + failed + " test(s) failed");
  process.exit(1);
} else {
  console.log("\nPASS — all nested sub-types tests passed");
  process.exit(0);
}
