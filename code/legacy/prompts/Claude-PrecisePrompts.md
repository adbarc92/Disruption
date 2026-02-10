# Specific Game Development Prompts

Use these focused prompts with the Game Development Template for optimal results.

## Document Analysis Prompts

### Design Document Analysis
```
Using the Game Development Template, analyze the attached game design documents in the `docs` directory for a 2.5D web-based RPG.

Focus specifically on:
- Game mechanics completeness and clarity
- Technical feasibility for web deployment
- Missing specifications that will impact implementation
- Potential design conflicts or ambiguities

Identify the top 5 most critical gaps that need resolution before architecture planning.
```

### Technical Requirements Analysis  
```
Using the Game Development Template, analyze the technical requirements for implementing [SPECIFIC_SYSTEM] in a TypeScript web game.

Evaluate:
- Performance implications and optimization needs
- Browser compatibility considerations
- Required third-party libraries or frameworks
- Integration points with other game systems

Provide specific technical recommendations with justifications.
```

## Architecture Prompts

### Core Game Architecture
```
Using the Game Development Template, design the core architecture for a 2.5D web-based game using TypeScript.

Requirements:
- 60 FPS target performance
- Modular system design
- Asset streaming capabilities
- Save/load game state
- Mobile-responsive design

Provide complete system architecture with module diagrams and technology stack justification.
```

### Specific System Architecture
```
Using the Game Development Template, architect the [SYSTEM_NAME] system for integration with an existing TypeScript game engine.

System Requirements:
[PASTE_SPECIFIC_REQUIREMENTS]

Focus on:
- Integration points with existing systems
- Data structures and APIs
- Performance considerations
- Testing strategy for this system
```

## Implementation Prompts

### Core Engine Implementation
```
Using the Game Development Template, implement the core game engine systems for a 2.5D TypeScript web game.

Implement:
- Game loop and state management
- Rendering system (Canvas/WebGL)
- Input handling system
- Asset loading and management
- Basic entity-component system

Follow the approved architecture from [REFERENCE_PREVIOUS_DISCUSSION].
```

### Game System Implementation
```
Using the Game Development Template, implement the [SYSTEM_NAME] system according to these specifications:

[PASTE_DETAILED_SPECIFICATIONS]

Requirements:
- Full TypeScript typing
- Comprehensive unit tests
- Integration with existing engine
- Performance benchmarks
- Documentation for public APIs
```

### Entity/Character Implementation
```
Using the Game Development Template, implement [ENTITY_TYPE] entities with the following specifications:

[PASTE_CHARACTER_SPECS]

Include:
- Entity class with proper inheritance
- Component attachments
- Behavior systems
- Animation integration
- Collision detection
- Performance optimization
```

## Testing & Validation Prompts

### System Testing Suite
```
Using the Game Development Template, create a comprehensive testing suite for the [SYSTEM_NAME] system.

Include:
- Unit tests for core functionality
- Integration tests with other systems
- Performance benchmarks
- Mock data and test scenarios
- Automated testing setup

Ensure tests cover edge cases and error conditions.
```

### Gameplay Testing Framework
```
Using the Game Development Template, implement a gameplay testing framework that validates:

- Core game mechanics function correctly
- Performance meets 60 FPS targets
- User interactions work as designed
- Save/load functionality preserves state
- Cross-browser compatibility

Provide both automated tests and manual testing guidelines.
```

## Debugging & Optimization Prompts

### Performance Analysis
```
Using the Game Development Template, analyze the performance of [SYSTEM/FEATURE] and identify optimization opportunities.

Current Issues:
[DESCRIBE_PERFORMANCE_PROBLEMS]

Provide:
- Profiling strategy and tools
- Specific bottleneck identification
- Optimization recommendations with impact estimates
- Implementation plan for improvements
```

### Bug Investigation
```
Using the Game Development Template, investigate and resolve this bug:

**Bug Description**: [DETAILED_BUG_REPORT]
**Reproduction Steps**: [STEP_BY_STEP]
**Expected Behavior**: [WHAT_SHOULD_HAPPEN]
**Actual Behavior**: [WHAT_ACTUALLY_HAPPENS]

Provide:
- Root cause analysis
- Fix implementation
- Prevention strategy
- Regression testing approach
```

## Documentation Prompts

### Technical Documentation
```
Using the Game Development Template, create comprehensive technical documentation for [SYSTEM/FEATURE].

Include:
- Architecture overview with diagrams
- API reference for public interfaces
- Integration guidelines for other developers
- Performance characteristics and limitations
- Troubleshooting guide

Target audience: Developers who need to integrate with or modify this system.
```

### Deployment Guide
```
Using the Game Development Template, create a complete deployment guide for the web-based game.

Cover:
- Build process and requirements
- Asset optimization and bundling
- Web server configuration
- CDN setup recommendations
- Monitoring and analytics integration
- Rollback procedures

Include both development and production deployment scenarios.
```

---

## Usage Instructions

1. **Start with Document Analysis** prompts to establish requirements
2. **Move to Architecture** prompts to plan technical approach  
3. **Use Implementation** prompts for focused development tasks
4. **Apply Testing** prompts to validate functionality
5. **Use Documentation** prompts to create maintainable deliverables

**Pro Tips**:
- Reference previous interactions: "Follow the architecture from [discussion]"
- Be specific with bracketed placeholders: [SYSTEM_NAME] = "Combat System"
- Combine prompts for complex tasks: Analysis → Architecture → Implementation
- Always include the Game Development Template reference for consistency