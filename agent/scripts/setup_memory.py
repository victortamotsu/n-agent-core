#!/usr/bin/env python3
"""
Setup Script - AgentCore Memory

Este script cria e configura o AgentCore Memory para o n-agent.
Deve ser executado uma única vez antes do primeiro deploy.

Uso:
    cd agent
    uv run python scripts/setup_memory.py

Ou para especificar região:
    uv run python scripts/setup_memory.py --region us-west-2
"""

import argparse
import os
import sys
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from bedrock_agentcore.memory import MemoryClient


def create_memory(
    memory_name: str = "n-agent-memory",
    region_name: str = "us-east-1",
    with_strategies: bool = True,
) -> str:
    """Create AgentCore Memory resource.

    Args:
        memory_name: Name for the memory resource
        region_name: AWS region
        with_strategies: Whether to include long-term memory strategies

    Returns:
        Memory ID
    """
    print(f"🔄 Initializing MemoryClient in {region_name}...")
    client = MemoryClient(region_name=region_name)

    # Check if memory already exists
    print("🔍 Checking for existing memories...")
    try:
        response = client.list_memories()
        memories = response if isinstance(response, list) else response.get("memories", [])
        
        for mem in memories:
            name = mem.get("name") if isinstance(mem, dict) else getattr(mem, "name", None)
            mem_id = mem.get("id") if isinstance(mem, dict) else getattr(mem, "id", None)
            
            if name == memory_name:
                print(f"✅ Memory already exists: {mem_id}")
                return mem_id
    except Exception as e:
        print(f"⚠️ Could not list memories: {e}")

    # Define strategies for long-term memory
    strategies = []
    if with_strategies:
        strategies = [
            {
                "summaryMemoryStrategy": {
                    "name": "TripSessionSummarizer",
                    "namespaces": ["/summaries/{actorId}/{sessionId}"],
                }
            },
            {
                "userPreferenceMemoryStrategy": {
                    "name": "TravelPreferences",
                    "namespaces": ["/users/{actorId}/preferences"],
                }
            },
        ]

    # Create new memory
    print(f"🔄 Creating memory '{memory_name}'...")
    print(f"   Strategies: {len(strategies)} configured")

    try:
        memory = client.create_memory_and_wait(
            name=memory_name,
            description="Session memory for n-agent travel assistant. "
                        "Stores conversation history, trip context, and user preferences.",
            strategies=strategies if strategies else None,
        )

        memory_id = memory.get("id") if isinstance(memory, dict) else getattr(memory, "id", None)
        print(f"✅ Memory created successfully!")
        print(f"   ID: {memory_id}")
        return memory_id

    except Exception as e:
        print(f"❌ Failed to create memory: {e}")
        raise


def save_memory_id(memory_id: str, env_file: str = ".env"):
    """Save memory ID to .env file.

    Args:
        memory_id: Memory ID to save
        env_file: Path to .env file
    """
    env_path = Path(__file__).parent.parent / env_file

    # Read existing content
    existing_content = ""
    if env_path.exists():
        existing_content = env_path.read_text()

    # Check if already set
    if "BEDROCK_AGENTCORE_MEMORY_ID" in existing_content:
        # Update existing
        lines = existing_content.split("\n")
        new_lines = []
        for line in lines:
            if line.startswith("BEDROCK_AGENTCORE_MEMORY_ID"):
                new_lines.append(f"BEDROCK_AGENTCORE_MEMORY_ID={memory_id}")
            else:
                new_lines.append(line)
        env_path.write_text("\n".join(new_lines))
        print(f"✅ Updated {env_file}")
    else:
        # Append
        with open(env_path, "a") as f:
            f.write(f"\n# AgentCore Memory ID (created by setup_memory.py)\n")
            f.write(f"BEDROCK_AGENTCORE_MEMORY_ID={memory_id}\n")
        print(f"✅ Added to {env_file}")


def update_yaml_config(memory_id: str):
    """Update .bedrock_agentcore.yaml with memory ID.

    Args:
        memory_id: Memory ID to set
    """
    yaml_path = Path(__file__).parent.parent / ".bedrock_agentcore.yaml"

    if not yaml_path.exists():
        print(f"⚠️ {yaml_path} not found")
        return

    content = yaml_path.read_text()

    # Check if already configured
    if "BEDROCK_AGENTCORE_MEMORY_ID:" in content:
        # Update the line
        lines = content.split("\n")
        new_lines = []
        for line in lines:
            if "BEDROCK_AGENTCORE_MEMORY_ID:" in line:
                # Preserve indentation
                indent = len(line) - len(line.lstrip())
                new_lines.append(f"{' ' * indent}BEDROCK_AGENTCORE_MEMORY_ID: {memory_id}")
            else:
                new_lines.append(line)
        yaml_path.write_text("\n".join(new_lines))
        print(f"✅ Updated .bedrock_agentcore.yaml")
    else:
        print(f"⚠️ BEDROCK_AGENTCORE_MEMORY_ID not found in yaml, add manually")


def main():
    parser = argparse.ArgumentParser(
        description="Setup AgentCore Memory for n-agent"
    )
    parser.add_argument(
        "--region",
        default="us-east-1",
        help="AWS region (default: us-east-1)",
    )
    parser.add_argument(
        "--name",
        default="n-agent-memory",
        help="Memory name (default: n-agent-memory)",
    )
    parser.add_argument(
        "--no-strategies",
        action="store_true",
        help="Create without long-term memory strategies",
    )

    args = parser.parse_args()

    print("=" * 60)
    print("🧠 N-Agent Memory Setup")
    print("=" * 60)
    print(f"Region: {args.region}")
    print(f"Name: {args.name}")
    print(f"Strategies: {'Disabled' if args.no_strategies else 'Enabled'}")
    print("=" * 60)

    try:
        # Create memory
        memory_id = create_memory(
            memory_name=args.name,
            region_name=args.region,
            with_strategies=not args.no_strategies,
        )

        # Save to files
        print("\n📝 Saving configuration...")
        save_memory_id(memory_id)
        update_yaml_config(memory_id)

        print("\n" + "=" * 60)
        print("✅ SETUP COMPLETE")
        print("=" * 60)
        print(f"\nMemory ID: {memory_id}")
        print("\nNext steps:")
        print("  1. Verify .env has BEDROCK_AGENTCORE_MEMORY_ID set")
        print("  2. Run: agentcore dev")
        print('  3. Test: agentcore invoke --dev \'{"prompt": "Olá!"}\'')
        print("\nFor production deploy:")
        print("  gh secret set BEDROCK_AGENTCORE_MEMORY_ID --body '{}'".format(memory_id))

    except Exception as e:
        print(f"\n❌ Setup failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
