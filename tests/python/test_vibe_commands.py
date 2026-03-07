"""
Test suite for Vibe custom commands
"""

import pytest
from unittest.mock import patch, MagicMock
from src.vibe_custom_commands import (
    register_custom_commands,
    add_custom_command_handlers,
    patch_vibe
)


class TestVibeCommands:
    """Test Vibe custom commands functionality"""
    
    def test_register_custom_commands(self):
        """Test that custom commands are registered correctly"""
        # Create a mock CommandRegistry class
        mock_registry = type('MockCommandRegistry', (), {
            'commands': {},
            '_alias_map': {},
            '__init__': lambda self, excluded=None: None
        })
        
        # Call the function
        register_custom_commands(mock_registry)
        
        # Check that commands were added
        assert 'use_hybrid_mode' in mock_registry.commands
        assert 'change_worker_model' in mock_registry.commands
        
        # Check aliases
        assert '/use_hybrid_mode' in mock_registry._alias_map
        assert '/change_worker_model' in mock_registry._alias_map
    
    def test_add_custom_command_handlers(self):
        """Test that custom command handlers are added"""
        # Create a mock VibeApp class
        mock_app = type('MockVibeApp', (), {
            '_mount_and_scroll': lambda self, msg: None,
            '_reload_config': lambda self: None
        })
        
        # Call the function
        add_custom_command_handlers(mock_app)
        
        # Check that methods were added
        assert hasattr(mock_app, '_handle_use_hybrid_mode')
        assert hasattr(mock_app, '_handle_change_worker_model')
        assert callable(mock_app._handle_use_hybrid_mode)
        assert callable(mock_app._handle_change_worker_model)
    
    @patch('src.vibe_custom_commands.CommandRegistry')
    @patch('src.vibe_custom_commands.VibeApp')
    @patch('src.vibe_custom_commands.UserCommandMessage')
    def test_patch_vibe(self, mock_msg, mock_app, mock_registry):
        """Test the complete patching process"""
        # Mock the classes
        mock_msg.return_value = 'UserCommandMessage'
        mock_app.return_value = MagicMock()
        mock_registry.return_value = MagicMock()
        
        # Call the function
        patch_vibe()
        
        # Check that functions were called
        assert register_custom_commands.called
        assert add_custom_command_handlers.called
    
    def test_command_registration_details(self):
        """Test command registration details"""
        mock_registry = type('MockCommandRegistry', (), {
            'commands': {},
            '_alias_map': {},
            '__init__': lambda self, excluded=None: None
        })
        
        register_custom_commands(mock_registry)
        
        # Check command details
        use_hybrid_cmd = mock_registry.commands['use_hybrid_mode']
        assert '/use_hybrid_mode' in use_hybrid_cmd.aliases
        assert 'Toggle between hybrid and single agent modes' in use_hybrid_cmd.description
        assert use_hybrid_cmd.handler == '_handle_use_hybrid_mode'
        
        change_model_cmd = mock_registry.commands['change_worker_model']
        assert '/change_worker_model' in change_model_cmd.aliases
        assert 'Change the worker model or toggle hybrid mode' in change_model_cmd.description
        assert change_model_cmd.handler == '_handle_change_worker_model'
    

class TestCommandHandlers:
    """Test command handler implementations"""
    
    def test_use_hybrid_mode_handler(self):
        """Test the use_hybrid_mode command handler"""
        # This would require more complex mocking
        # For now, just verify the function exists and is callable
        from src.vibe_custom_commands import _handle_use_hybrid_mode
        assert callable(_handle_use_hybrid_mode)
    
    def test_change_worker_model_handler(self):
        """Test the change_worker_model command handler"""
        # This would require more complex mocking
        # For now, just verify the function exists and is callable
        from src.vibe_custom_commands import _handle_change_worker_model
        assert callable(_handle_change_worker_model)


class TestLoadExtensions:
    """Test the load_vibe_extensions module"""
    
    @patch('builtins.print')
    def test_main_function(self, mock_print):
        """Test the main function of load_vibe_extensions"""
        from src.load_vibe_extensions import main
        
        # Test with --help
        with pytest.raises(SystemExit):
            main(['--help'])
        
        # Check that help was printed
        assert any('Mistral Vibe Hybrid Setup Packaging Script' in str(call) 
                  for call in mock_print.call_args_list)
    
    def test_version_display(self):
        """Test version display"""
        from src.load_vibe_extensions import show_version
        
        # Capture output
        import io
        from contextlib import redirect_stdout
        
        f = io.StringIO()
        with redirect_stdout(f):
            show_version()
        
        output = f.getvalue()
        assert 'v1.0.0' in output
        assert 'Mistral Vibe Hybrid Setup Packaging Script' in output


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
