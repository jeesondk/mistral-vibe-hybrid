"""
Test suite for Vibe custom commands
"""

import asyncio
import inspect
import os
import subprocess
import sys
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.vibe_custom_commands import (
    add_custom_command_handlers,
    patch_vibe,
    register_custom_commands,
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_registry_class():
    """Create a mock CommandRegistry class for testing."""
    return type(
        "MockCommandRegistry",
        (),
        {
            "commands": {},
            "_alias_map": {},
            "__init__": lambda self, excluded_commands=None: None,
        },
    )


def _make_app_class():
    """Create a mock VibeApp class with async stubs."""
    return type(
        "MockVibeApp",
        (),
        {
            "_mount_and_scroll": AsyncMock(),
            "_reload_config": AsyncMock(),
        },
    )


def _attach_handlers(app_class=None, msg_class=None):
    """Attach handlers and return (app_class, MockMsg)."""
    if app_class is None:
        app_class = _make_app_class()
    if msg_class is None:
        msg_class = MagicMock(side_effect=lambda text: text)
    add_custom_command_handlers(app_class, UserCommandMessage=msg_class)
    return app_class, msg_class


# ===========================================================================
# Command registration
# ===========================================================================


class TestRegisterCustomCommands:
    def test_registers_both_commands(self):
        cls = _make_registry_class()
        register_custom_commands(cls)
        instance = cls()

        assert "use_hybrid_mode" in instance.commands
        assert "change_worker_model" in instance.commands

    def test_registers_aliases(self):
        cls = _make_registry_class()
        register_custom_commands(cls)
        instance = cls()

        for alias in ["/use_hybrid_mode", "/hybrid_mode", "/toggle_mode"]:
            assert alias in instance._alias_map
        for alias in ["/change_worker_model", "/worker_model", "/model"]:
            assert alias in instance._alias_map

    def test_excluded_commands_not_registered(self):
        cls = _make_registry_class()
        register_custom_commands(cls)
        instance = cls(excluded_commands=["use_hybrid_mode"])

        assert "use_hybrid_mode" not in instance.commands
        assert "change_worker_model" in instance.commands

    def test_exclude_both(self):
        cls = _make_registry_class()
        register_custom_commands(cls)
        instance = cls(excluded_commands=["use_hybrid_mode", "change_worker_model"])

        assert "use_hybrid_mode" not in instance.commands
        assert "change_worker_model" not in instance.commands

    def test_command_metadata(self):
        cls = _make_registry_class()
        register_custom_commands(cls)
        instance = cls()

        cmd = instance.commands["use_hybrid_mode"]
        assert "/use_hybrid_mode" in cmd.aliases
        assert cmd.handler == "_handle_use_hybrid_mode"
        assert cmd.exits is False

        cmd = instance.commands["change_worker_model"]
        assert "/change_worker_model" in cmd.aliases
        assert cmd.handler == "_handle_change_worker_model"
        assert cmd.exits is False


# ===========================================================================
# Handler attachment
# ===========================================================================


class TestAddCustomCommandHandlers:
    def test_attaches_handlers(self):
        app_cls, _ = _attach_handlers()
        assert hasattr(app_cls, "_handle_use_hybrid_mode")
        assert hasattr(app_cls, "_handle_change_worker_model")

    def test_handlers_are_coroutines(self):
        app_cls, _ = _attach_handlers()
        assert inspect.iscoroutinefunction(app_cls._handle_use_hybrid_mode)
        assert inspect.iscoroutinefunction(app_cls._handle_change_worker_model)

    def test_raises_without_user_command_message(self):
        app_cls = _make_app_class()
        with pytest.raises(AssertionError, match="UserCommandMessage not set"):
            add_custom_command_handlers(app_cls, UserCommandMessage=None)


# ===========================================================================
# _handle_use_hybrid_mode
# ===========================================================================


class TestHandleUseHybridMode:
    def _run(self, instance, mode=""):
        asyncio.run(type(instance)._handle_use_hybrid_mode(instance, mode=mode))

    def test_missing_script(self, tmp_path):
        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance, mode="hybrid")

        instance._mount_and_scroll.assert_called_once()
        assert "not found" in msg.call_args[0][0]

    def test_switch_to_hybrid_success(self, tmp_path):
        script = tmp_path / "toggle_hybrid_mode.sh"
        script.write_text("#!/bin/bash\nexit 0\n")
        script.chmod(0o755)

        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance, mode="hybrid")

        instance._reload_config.assert_called_once()
        assert "hybrid" in msg.call_args[0][0].lower()

    def test_switch_to_single_success(self, tmp_path):
        script = tmp_path / "toggle_hybrid_mode.sh"
        script.write_text("#!/bin/bash\nexit 0\n")
        script.chmod(0o755)

        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance, mode="single")

        instance._reload_config.assert_called_once()
        assert "single" in msg.call_args[0][0].lower()

    def test_switch_shorthand_h(self, tmp_path):
        script = tmp_path / "toggle_hybrid_mode.sh"
        script.write_text("#!/bin/bash\nexit 0\n")
        script.chmod(0o755)

        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance, mode="h")

        assert "hybrid" in msg.call_args[0][0].lower()

    def test_switch_shorthand_s(self, tmp_path):
        script = tmp_path / "toggle_hybrid_mode.sh"
        script.write_text("#!/bin/bash\nexit 0\n")
        script.chmod(0o755)

        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance, mode="s")

        assert "single" in msg.call_args[0][0].lower()

    def test_switch_failure(self, tmp_path):
        script = tmp_path / "toggle_hybrid_mode.sh"
        script.write_text("#!/bin/bash\necho 'boom' >&2; exit 1\n")
        script.chmod(0o755)

        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance, mode="hybrid")

        instance._reload_config.assert_not_called()
        assert "error" in msg.call_args[0][0].lower()

    def test_status_query_success(self, tmp_path):
        script = tmp_path / "toggle_hybrid_mode.sh"
        script.write_text("#!/bin/bash\necho 'hybrid mode active'\n")
        script.chmod(0o755)

        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance, mode="")

        assert "hybrid mode active" in msg.call_args[0][0]

    def test_status_query_failure(self, tmp_path):
        script = tmp_path / "toggle_hybrid_mode.sh"
        script.write_text("#!/bin/bash\necho 'bad' >&2; exit 1\n")
        script.chmod(0o755)

        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance, mode="")

        assert "error" in msg.call_args[0][0].lower()


# ===========================================================================
# _handle_change_worker_model
# ===========================================================================


class TestHandleChangeWorkerModel:
    def _run(self, instance, model_path=""):
        asyncio.run(type(instance)._handle_change_worker_model(instance, model_path=model_path))

    def test_missing_script(self, tmp_path):
        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance)

        assert "not found" in msg.call_args[0][0]

    def test_no_args_shows_menu(self, tmp_path):
        script = tmp_path / "change_worker_model.sh"
        script.write_text("#!/bin/bash\necho 'Select a model:'\n")
        script.chmod(0o755)

        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance, model_path="")

        assert "menu" in msg.call_args[0][0].lower()

    def test_no_args_error(self, tmp_path):
        script = tmp_path / "change_worker_model.sh"
        script.write_text("#!/bin/bash\necho 'fail' >&2; exit 1\n")
        script.chmod(0o755)

        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance, model_path="")

        assert "error" in msg.call_args[0][0].lower()

    def test_list_success(self, tmp_path):
        script = tmp_path / "change_worker_model.sh"
        script.write_text("#!/bin/bash\necho 'model-a.gguf'\necho 'model-b.gguf'\n")
        script.chmod(0o755)

        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance, model_path="--list")

        assert "model-a.gguf" in msg.call_args[0][0]

    def test_list_error(self, tmp_path):
        script = tmp_path / "change_worker_model.sh"
        script.write_text("#!/bin/bash\necho 'err' >&2; exit 1\n")
        script.chmod(0o755)

        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance, model_path="--list")

        assert "error" in msg.call_args[0][0].lower()

    def test_specific_model_success(self, tmp_path):
        script = tmp_path / "change_worker_model.sh"
        script.write_text("#!/bin/bash\nexit 0\n")
        script.chmod(0o755)

        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance, model_path="/models/my-model.gguf")

        instance._reload_config.assert_called_once()
        assert "success" in msg.call_args[0][0].lower()

    def test_specific_model_failure(self, tmp_path):
        script = tmp_path / "change_worker_model.sh"
        script.write_text("#!/bin/bash\necho 'not found' >&2; exit 1\n")
        script.chmod(0o755)

        app_cls, msg = _attach_handlers()
        instance = app_cls()

        with patch.dict(os.environ, {"VIBE_PROJECT_ROOT": str(tmp_path)}):
            self._run(instance, model_path="/models/bad.gguf")

        instance._reload_config.assert_not_called()
        assert "error" in msg.call_args[0][0].lower()


# ===========================================================================
# patch_vibe
# ===========================================================================


class TestPatchVibe:
    @patch("src.vibe_custom_commands.add_custom_command_handlers")
    @patch("src.vibe_custom_commands.register_custom_commands")
    def test_calls_registration_and_handlers(self, mock_register, mock_add):
        mock_cmd_registry = MagicMock()
        mock_vibe_app = MagicMock()
        mock_user_msg = MagicMock()

        with patch.dict(
            "sys.modules",
            {
                "vibe": MagicMock(),
                "vibe.cli": MagicMock(),
                "vibe.cli.commands": MagicMock(CommandRegistry=mock_cmd_registry),
                "vibe.cli.textual_ui": MagicMock(),
                "vibe.cli.textual_ui.app": MagicMock(VibeApp=mock_vibe_app),
                "vibe.cli.textual_ui.widgets": MagicMock(),
                "vibe.cli.textual_ui.widgets.messages": MagicMock(UserCommandMessage=mock_user_msg),
            },
        ):
            patch_vibe()

        mock_register.assert_called_once_with(mock_cmd_registry)
        mock_add.assert_called_once_with(mock_vibe_app, mock_user_msg)

    @patch("src.vibe_custom_commands.add_custom_command_handlers")
    @patch("src.vibe_custom_commands.register_custom_commands")
    def test_sets_module_level_user_command_message(self, _mock_reg, _mock_add):
        import src.vibe_custom_commands as mod

        old_val = mod._UserCommandMessage
        try:
            mock_user_msg = MagicMock()
            with patch.dict(
                "sys.modules",
                {
                    "vibe": MagicMock(),
                    "vibe.cli": MagicMock(),
                    "vibe.cli.commands": MagicMock(CommandRegistry=MagicMock()),
                    "vibe.cli.textual_ui": MagicMock(),
                    "vibe.cli.textual_ui.app": MagicMock(VibeApp=MagicMock()),
                    "vibe.cli.textual_ui.widgets": MagicMock(),
                    "vibe.cli.textual_ui.widgets.messages": MagicMock(
                        UserCommandMessage=mock_user_msg
                    ),
                },
            ):
                patch_vibe()

            assert mod._UserCommandMessage is mock_user_msg
        finally:
            mod._UserCommandMessage = old_val

    @patch("sys.exit")
    def test_exits_on_import_error(self, mock_exit):
        patch_vibe()
        mock_exit.assert_called_once_with(1)


# ===========================================================================
# load_vibe_extensions.py (tested via subprocess since it calls sys.exit)
# ===========================================================================


class TestLoadVibeExtensions:
    def test_exits_when_vibe_not_available(self):
        """When vibe is not installed and not in PATH, the loader should exit non-zero."""
        project_root = os.path.join(os.path.dirname(__file__), "../..")
        result = subprocess.run(
            [sys.executable, "-c", "import src.load_vibe_extensions"],
            capture_output=True,
            text=True,
            env={**os.environ, "PATH": ""},
            cwd=project_root,
        )
        assert result.returncode != 0

    def test_module_compiles_without_syntax_errors(self):
        project_root = os.path.join(os.path.dirname(__file__), "../..")
        result = subprocess.run(
            [sys.executable, "-m", "py_compile", "src/load_vibe_extensions.py"],
            capture_output=True,
            text=True,
            cwd=project_root,
        )
        assert result.returncode == 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
