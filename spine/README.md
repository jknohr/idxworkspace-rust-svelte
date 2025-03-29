# Spine Framework

Spine is a modular framework for building AI-powered agents and applications in Rust. It provides a set of core components that work together to enable flexible, powerful agent architectures.

## Architecture

The Spine framework is built on a clear separation of concerns between different components:

### Model Context Protocol (MCP)

The Model Context Protocol provides a standardized way for applications to provide context to AI models. Think of MCP like a USB-C port for AI applications - it standardizes how different components connect to each other.

MCP includes:
- **Tools**: Executable functions that can be discovered and called by LLMs
- **Resources**: Data and content that can be accessed through the protocol
- **Prompts**: Reusable templates and workflows

MCP is implemented in the `spine-mcp` crate.

### LLM Routing

Large Language Models (LLMs) provide the core reasoning capabilities for agents. The LLM routing layer:
- Manages connections to multiple LLM providers (OpenAI, Anthropic, etc.)
- Handles routing, fallbacks, and retries
- Provides streaming and caching
- Abstracts away provider-specific details

LLM routing is implemented in the `spine-llm-router` crate.

### Agent System

Agents combine MCP and LLMs to perform tasks and achieve goals. The agent layer:
- Manages agent state and memory
- Coordinates tool and resource usage
- Implements workflows and planning
- Provides extension mechanisms

## Crates

The project is organized into several crates:

- `spine-mcp`: Implementation of the Model Context Protocol
- `spine-mcp-macros`: Procedural macros for MCP tool creation
- `spine-llm-router`: LLM provider management and routing
- `spine-core`: Core types and traits shared across crates
- `spine-agent`: Agent implementation (planning, memory, workflows)

## How These Components Interact

In a typical agent workflow:

1. An agent receives a task and plans how to complete it
2. The agent uses the LLM router to get responses from language models
3. The LLM can access tools and resources via MCP
4. The agent uses the information and tool outputs to complete the task

## Getting Started

To get started with Spine, you can explore the example code in each crate:

- For MCP: `spine-mcp/examples/simple_server.rs`
- For LLM routing: `spine-llm-router/examples/simple_router.rs`
- For agents: `spine-agent/examples/simple_agent.rs`

## Project Status

This project is under active development. APIs may change as we continue to refine the architecture.

## License

This project is dual-licensed under MIT and Apache 2.0 licenses. 