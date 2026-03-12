# Universal Programming Principles

These principles define a general engineering philosophy that can guide both human developers and AI agents across any project, language, or architecture.

---

# 1. Long-Term Correctness Over Short-Term Cost

System design must prioritize long-term correctness rather than short-term implementation cost.

When multiple solutions exist, the decision priority is:

1. Architectural correctness  
2. Design consistency  
3. Maintainability  
4. Extensibility  
5. Implementation cost  

Implementation cost must always be the lowest priority.

---

# 2. Do Not Sacrifice Design to Reduce Cost

Reducing code size, implementation time, or complexity must **never** justify weakening the system design.

The following are not allowed for the sake of convenience:

- Simplifying a correct domain or data model
- Breaking architectural structure
- Introducing temporary or hack solutions
- Creating unnecessary technical debt
- Violating established design rules

If a choice exists between:

- **A:** Architecturally correct but more complex solution  
- **B:** Simpler but structurally weaker solution  

The correct decision is **always A**.

---

# 3. Complexity Is Acceptable, Disorder Is Not

Complex systems are acceptable.  
Disordered systems are not.

The following are acceptable when they improve clarity and structure:

- Clear modular boundaries
- Explicit interface layers
- Detailed domain or data models
- Multiple files and modules
- Higher code volume

Complexity is acceptable when it improves structure and understanding.

---

# 4. Consistency Over Local Optimization

Local optimization must not break system-wide consistency.

Consistency must be preserved in:

- Naming conventions
- Architectural rules
- Design patterns
- Module structures

Even if a local change appears simpler, it must not break global consistency.

---

# 5. Explicitness Over Implicitness

System behavior should be:

- Explicit
- Readable
- Understandable
- Traceable

Avoid:

- Hidden logic
- Implicit side effects
- Magic behavior
- Unclear control flow

A developer should always be able to reason about system behavior.

---

# 6. Design Before Implementation

Implementation should not begin before the following are clearly defined:

- System boundaries
- Module structure
- Data models
- Interfaces between components

Structure should guide implementation rather than emerge accidentally.

---

# 7. Systems Must Be Evolvable

Software systems should be designed to evolve.

The architecture should allow:

- Future feature expansion
- Module replacement
- System refactoring
- Architectural upgrades

Rigid or fragile structures should be avoided.

---

# 8. Errors Must Be Diagnosable

Failures must be visible and diagnosable.

Systems must avoid:

- Silent failures
- Hidden errors
- Swallowed exceptions
- Ambiguous failure states

Errors should be detectable, explainable, and traceable.

---

# 9. Abstraction Must Improve Understanding

Abstraction should exist only when it improves clarity.

Valid reasons for abstraction include:

- Reducing cognitive load
- Simplifying mental models
- Isolating complexity

Abstraction should **not** be introduced merely for elegance or perceived sophistication.

---

# 10. Technical Debt Is a System Risk

Technical debt must be treated as a real system risk.

If technical debt is introduced:

- It must be explicitly documented
- The reason must be clear
- A plan to resolve it should exist

Technical debt must never become invisible.

---

# Core Principle

**Prefer architectural correctness over implementation convenience.**