"""
Custom commands for Mistral Vibe extension
This module adds /use_hybrid_mode and /change_worker_model commands to Vibe
"""

import os
import subprocess
import sys
from pathlib import Path
from typing import Dict, Any, Optional

# Add the custom commands to Vibe's command registry

def register_custom_commands(command_registry_class: type) -> None:
    """
    Monkey-patch the CommandRegistry class to include custom commands
    """
    original_init = command_registry_class.__init__
    
    def new_init(self, excluded_commands=None):
        # Call original init
        original_init(self, excluded_commands)
        
        # Add custom commands
        if excluded_commands is None:
            excluded_commands = []
            
        # Only add commands if they're not excluded
        if "use_hybrid_mode" not in excluded_commands:
            self.commands["use_hybrid_mode"] = type('Command', (), {
                'aliases': frozenset(["/use_hybrid_mode", "/hybrid_mode", "/toggle_mode"]),
                'description': "Toggle between hybrid and single agent modes",
                'handler': "_handle_use_hybrid_mode",
                'exits': False
            })()
            
            # Add to alias map
            for alias in ["/use_hybrid_mode", "/hybrid_mode", "/toggle_mode"]:
                self._alias_map[alias] = "use_hybrid_mode"
                
        if "change_worker_model" not in excluded_commands:
            self.commands["change_worker_model"] = type('Command', (), {
                'aliases': frozenset(["/change_worker_model", "/worker_model", "/model"]),
                'description': "Change the worker model or toggle hybrid mode",
                'handler': "_handle_change_worker_model",
                'exits': False
            })()
            
            # Add to alias map
            for alias in ["/change_worker_model", "/worker_model", "/model"]:
                self._alias_map[alias] = "change_worker_model"
    
    command_registry_class.__init__ = new_init


def add_custom_command_handlers(app_class: type) -> None:
    """
    Add custom command handler methods to the VibeApp class
    """
    
    async def _handle_use_hybrid_mode(self, mode: str = "") -> None:
        """Handle /use_hybrid_mode command"""
        project_root = os.environ.get('VIBE_PROJECT_ROOT', os.getcwd())
        toggle_script = os.path.join(project_root, 'toggle_hybrid_mode.sh')
        
        if not os.path.exists(toggle_script):
            await self._mount_and_scroll(
                UserCommandMessage("❌ Error: toggle_hybrid_mode.sh not found. Run setup_mistral_vibe.sh first.")
            )
            return
        
        # Determine which mode to switch to
        if mode.lower() in ['hybrid', 'h']:
            target_mode = 'hybrid'
        elif mode.lower() in ['single', 's']:
            target_mode = 'single'
        else:
            # Show current status
            result = subprocess.run([toggle_script, 'status'], capture_output=True, text=True)
            if result.returncode == 0:
                await self._mount_and_scroll(
                    UserCommandMessage(f"Current mode: {result.stdout.strip()}")
                )
            else:
                await self._mount_and_scroll(
                    UserCommandMessage(f"❌ Error getting status: {result.stderr}")
                )
            return
        
        # Execute the toggle script
        result = subprocess.run([toggle_script, target_mode], capture_output=True, text=True)
        
        if result.returncode == 0:
            await self._reload_config()
            await self._mount_and_scroll(
                UserCommandMessage(f"✅ Switched to {target_mode} mode")
            )
        else:
            await self._mount_and_scroll(
                UserCommandMessage(f"❌ Error: {result.stderr}")
            )
    
    async def _handle_change_worker_model(self, model_path: str = "") -> None:
        """Handle /change_worker_model command"""
        project_root = os.environ.get('VIBE_PROJECT_ROOT', os.getcwd())
        change_script = os.path.join(project_root, 'change_worker_model.sh')
        
        if not os.path.exists(change_script):
            await self._mount_and_scroll(
                UserCommandMessage("❌ Error: change_worker_model.sh not found. Run setup_mistral_vibe.sh first.")
            )
            return
        
        if not model_path:
            # Show interactive menu
            result = subprocess.run([change_script], capture_output=True, text=True)
            if result.returncode == 0:
                await self._mount_and_scroll(
                    UserCommandMessage(f"Model changer menu:\n{result.stdout}")
                )
            else:
                await self._mount_and_scroll(
                    UserCommandMessage(f"❌ Error: {result.stderr}")
                )
        elif model_path.lower() == '--list':
            # Show model list
            result = subprocess.run([change_script, '--list'], capture_output=True, text=True)
            if result.returncode == 0:
                await self._mount_and_scroll(
                    UserCommandMessage(f"Available models:\n{result.stdout}")
                )
            else:
                await self._mount_and_scroll(
                    UserCommandMessage(f"❌ Error: {result.stderr}")
                )
        else:
            # Change to specific model
            result = subprocess.run([change_script, model_path], capture_output=True, text=True)
            if result.returncode == 0:
                await self._reload_config()
                await self._mount_and_scroll(
                    UserCommandMessage(f"✅ Worker model changed successfully")
                )
            else:
                await self._mount_and_scroll(
                    UserCommandMessage(f"❌ Error: {result.stderr}")
                )
    
    # Add the methods to the app class
    setattr(app_class, '_handle_use_hybrid_mode', _handle_use_hybrid_mode)
    setattr(app_class, '_handle_change_worker_model', _handle_change_worker_model)


def patch_vibe():
    """
    Apply monkey patches to extend Vibe with custom commands
    """
    try:
        # Import Vibe modules
        from vibe.cli.commands import CommandRegistry
        from vibe.cli.textual_ui.app import VibeApp
        from vibe.cli.textual_ui.widgets.messages import UserCommandMessage
        
        # Make UserCommandMessage available in this scope
        global UserCommandMessage
        UserCommandMessage = UserCommandMessage
        
        # Register custom commands
        register_custom_commands(CommandRegistry)
        add_custom_command_handlers(VibeApp)
        
        print("✅ Vibe custom commands registered successfully!")
        print("Available commands:")
        print("  /use_hybrid_mode [hybrid|single] - Toggle between modes")
        print("  /change_worker_model [model_path|--list] - Change worker model")
        
    except Exception as e:
        print(f"❌ Error patching Vibe: {e}")
        sys.exit(1)


if __name__ == "__main__":
    patch_vibe()
