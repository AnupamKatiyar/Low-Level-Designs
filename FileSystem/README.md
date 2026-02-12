# Project Requirements

Our File System is designed to be a robust, hierarchical data management solution.

---

### 📄 File Operations
*   **Create/Read/Delete:** Full lifecycle management.
*   **Write & Overwrite:** Support for modifying file content.
*   **Metadata:** Track file size and timestamps.
*   **Storage:** Full support for both **text** and **binary** types.

### 📂 Directory Operations
*   **Structure:** Support for nested, recursive directory trees.
*   **Management:** Ability to create directories and add/remove children.
*   **Navigation:** List children and traverse the system.

### 🔐 Permission Management
*   **Permissions:** Implementation of **Read (r)**, **Write (w)**, and **Execute (x)**.
*   **Scope:** Applied consistently across both files and directories.

### ⚠️ Error Handling & Scalability
*   **Error Cases:** Handling for invalid permissions, file not found, and duplicate names.
*   **Performance:** Optimized for very large directory trees with efficient search.
*   **Extensibility:** Designed to support symbolic links, versioning, and caching.
