"""
Test suite for Vibe custom commands
"""

import pytest
from unittest.mock import patch, MagicMock, AsyncMock
from src.vibe_custom_commands import (
    register_custom_commands,
    add_custom_command_handlers,
    patch_vibe
)


class TestVibeCommands:
    """Test Vibe custom commands functionality"""

    def test_register_custom_commands(self):
        """Test that custom commands are registered correctly"""
        mock_registry = type('MockCommandRegistry', (), {
            'commands': {},
            '_alias_map': {},
            '__init__': lambda self, excluded=None: None
        })

        register_custom_commands(mock_registry)

        # Instantiate to trigger the patched __init__
        instance = mock_registry()

        assert 'use_hybrid_mode' in instance.commands
        assert 'change_worker_model' in instance.commands
        assert '/use_hybrid_mode' in instance._alias_map
        assert '/change_worker_model' in instance._alias_map

    def test_register_excludes_commands(self):
        """Test that excluded commands are not registered"""
        mock_registry = type('MockCommandRegistry', (), {
            'commands': {},
            '_alias_map': {},
            '__init__': lambda self, excluded_commands=None: None
        })

        register_custom_commands(mock_registry)
        instance = mock_registry(excluded_commands=["use_hybrid_mode"])

        assert 'use_hybrid_mode' not in instance.commands
        assert 'change_worker_model' in instance.commands

    def test_add_custom_command_handlers(self):
        """Test that custom command handlers are added to the class"""
        MockMsg = MagicMock()
        mock_app = type('MockVibeApp', (), {
            '_mount_and_scroll': AsyncMock(),
            '_reload_config': AsyncMock()
        })

        add_custom_command_handlers(mock_app, UserCommandMessage=MockMsg)

        assert hasattr(mock_app, '_handle_use_hybrid_mode')
        assert hasattr(mock_app, '_handle_change_worker_model')
        assert callable(mock_app._handle_use_hybrid_mode)
        assert callable(mock_app._handle_change_worker_model)

    def test_command_registration_details(self):
        """Test command registration details"""
        mock_registry = type('MockCommandRegistry', (), {
            'commands': {},
            '_alias_map': {},
            '__init__': lambda self, excluded=None: None
        })

        register_custom_commands(mock_registry)
        instance = mock_registry()

        use_hybrid_cmd = instance.commands['use_hybrid_mode']
        assert '/use_hybrid_mode' in use_hybrid_cmd.aliases
        assert 'Toggle between hybrid and single agent modes' in use_hybrid_cmd.description
        assert use_hybrid_cmd.handler == '_handle_use_hybrid_mode'

        change_model_cmd = instance.commands['change_worker_model']
        assert '/change_worker_model' in change_model_cmd.aliases
        assert 'Change the worker model or toggle hybrid mode' in change_model_cmd.description
        assert change_model_cmd.handler == '_handle_change_worker_model'


class TestCommandHandlers:
    """Test command handler implementations via add_custom_command_handlers"""

    def test_handlers_are_async(self):
        """Test that the handlers are async functions"""
        import inspect
        MockMsg = MagicMock()
        mock_app = type('MockVibeApp', (), {
            '_mount_and_scroll': AsyncMock(),
            '_reload_config': AsyncMock()
        })

        add_custom_command_handlers(mock_app, UserCommandMessage=MockMsg)

        assert inspect.iscoroutinefunction(mock_app._handle_use_hybrid_mode)
        assert inspect.iscoroutinefunction(mock_app._handle_change_worker_model)

    def test_use_hybrid_mode_missing_script(self, tmp_path):
        """Test use_hybrid_mode when toggle script is missing"""
        import asyncio
        MockMsg = MagicMock(return_value="error_msg")
        mock_app_cls = type('MockVibeApp', (), {
            '_mount_and_scroll': AsyncMock(),
            '_reload_config': AsyncMock()
        })

        add_custom_command_handlers(mock_app_cls, UserCommandMessage=MockMsg)

        instance = mock_app_cls()
        with patch.dict('os.environ', {'VIBE_PROJECT_ROOT': str(tmp_path)}):
            asyncio.run(
                mock_app_cls._handle_use_hybrid_mode(instance, mode="hybrid")
            )

        instance._mount_and_scroll.assert_called_once()
        MockMsg.assert_called_once()
        assert "not found" in str(MockMsg.call_args)


class TestPatchVibe:
    """Test the patch_vibe function"""

    @patch('src.vibe_custom_commands.add_custom_command_handlers')
    @patch('src.vibe_custom_commands.register_custom_commands')
    def test_patch_vibe_calls_registration(self, mock_register, mock_add_handlers):
        """Test that patch_vibe calls register and add_handlers"""
        mock_cmd_registry = MagicMock()
        mock_vibe_app = MagicMock()
        mock_user_msg = MagicMock()

        with patch.dict('sys.modules', {
            'vibe': MagicMock(),
            'vibe.cli': MagicMock(),
            'vibe.cli.commands': MagicMock(CommandRegistry=mock_cmd_registry),
            'vibe.cli.textual_ui': MagicMock(),
            'vibe.cli.textual_ui.app': MagicMock(VibeApp=mock_vibe_app),
            'vibe.cli.textual_ui.widgets': MagicMock(),
            'vibe.cli.textual_ui.widgets.messages': MagicMock(UserCommandMessage=mock_user_msg),
        }):
            patch_vibe()

        mock_register.assert_called_once_with(mock_cmd_registry)
        mock_add_handlers.assert_called_once_with(mock_vibe_app, mock_user_msg)


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
