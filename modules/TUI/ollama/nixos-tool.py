"""
title: NixOS Helper
author: zeev
description: Search NixOS options and packages
required_open_webui_version: 0.4.0
version: 0.1.0
licence: MIT
"""

import subprocess
import json
from pydantic import BaseModel, Field


class Tools:
    def __init__(self):
        """Initialize the NixOS Tool."""
        self.valves = self.Valves()

    class Valves(BaseModel):
        flake_path: str = Field(
            "/home/zeev/src/nix-config",
            description="Path to your NixOS flake"
        )

    async def search_nixos_options(
        self,
        query: str,
        __event_emitter__=None,
    ) -> str:
        """
        Search NixOS options by name or description.
        :param query: The search term to find NixOS options (e.g., "networking.firewall", "services.nginx")
        :return: Matching NixOS options with their descriptions and types
        """
        if __event_emitter__:
            await __event_emitter__({
                "type": "status",
                "data": {"description": f"Searching NixOS options for '{query}'...", "done": False}
            })

        try:
            # Use nix-env to search options
            result = subprocess.run(
                ["nix", "search", "nixpkgs", query, "--json"],
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode != 0:
                # Try searching with nixos-option
                result = subprocess.run(
                    ["nixos-option", "-r", query],
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                output = result.stdout if result.stdout else f"No options found for '{query}'"
            else:
                # Parse JSON output
                try:
                    options = json.loads(result.stdout)
                    if options:
                        output = "Found options:\n\n"
                        for name, info in list(options.items())[:10]:
                            desc = info.get("description", "No description")
                            version = info.get("version", "")
                            output += f"**{name}**\n"
                            if version:
                                output += f"  Version: {version}\n"
                            output += f"  {desc}\n\n"
                    else:
                        output = f"No options found for '{query}'"
                except json.JSONDecodeError:
                    output = result.stdout

        except subprocess.TimeoutExpired:
            output = "Search timed out. Try a more specific query."
        except Exception as e:
            output = f"Error searching options: {str(e)}"

        if __event_emitter__:
            await __event_emitter__({
                "type": "status",
                "data": {"description": "Search complete", "done": True}
            })

        return output

    async def search_nix_packages(
        self,
        package_name: str,
        __event_emitter__=None,
    ) -> str:
        """
        Search for Nix packages by name.
        :param package_name: The package name to search for (e.g., "firefox", "vim", "python")
        :return: List of matching packages with descriptions
        """
        if __event_emitter__:
            await __event_emitter__({
                "type": "status",
                "data": {"description": f"Searching packages for '{package_name}'...", "done": False}
            })

        try:
            result = subprocess.run(
                ["nix", "search", "nixpkgs", package_name, "--json"],
                capture_output=True,
                text=True,
                timeout=60
            )

            if result.returncode == 0 and result.stdout:
                try:
                    packages = json.loads(result.stdout)
                    if packages:
                        output = f"Found {len(packages)} packages:\n\n"
                        for name, info in list(packages.items())[:15]:
                            # Extract just the package name from legacyPackages.x86_64-linux.pkgname
                            short_name = name.split(".")[-1] if "." in name else name
                            desc = info.get("description", "No description")
                            version = info.get("version", "")
                            output += f"**{short_name}**"
                            if version:
                                output += f" ({version})"
                            output += f"\n  {desc}\n\n"
                    else:
                        output = f"No packages found for '{package_name}'"
                except json.JSONDecodeError:
                    output = result.stdout
            else:
                output = f"No packages found for '{package_name}'"
                if result.stderr:
                    output += f"\nError: {result.stderr}"

        except subprocess.TimeoutExpired:
            output = "Search timed out. Try a more specific query."
        except Exception as e:
            output = f"Error searching packages: {str(e)}"

        if __event_emitter__:
            await __event_emitter__({
                "type": "status",
                "data": {"description": "Search complete", "done": True}
            })

        return output

    async def get_nixos_option_info(
        self,
        option_path: str,
        __event_emitter__=None,
    ) -> str:
        """
        Get detailed information about a specific NixOS option.
        :param option_path: The full path of the NixOS option (e.g., "services.nginx.enable", "networking.firewall.allowedTCPPorts")
        :return: Detailed information including type, default value, and description
        """
        if __event_emitter__:
            await __event_emitter__({
                "type": "status",
                "data": {"description": f"Getting info for '{option_path}'...", "done": False}
            })

        try:
            result = subprocess.run(
                ["nixos-option", option_path],
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode == 0:
                output = result.stdout
            else:
                # Try with man page
                output = f"Option '{option_path}' not found or not set.\n"
                output += "Tip: Use search_nixos_options to find available options."

        except subprocess.TimeoutExpired:
            output = "Request timed out."
        except Exception as e:
            output = f"Error getting option info: {str(e)}"

        if __event_emitter__:
            await __event_emitter__({
                "type": "status",
                "data": {"description": "Complete", "done": True}
            })

        return output

    async def eval_nix_expression(
        self,
        expression: str,
        __event_emitter__=None,
    ) -> str:
        """
        Evaluate a Nix expression and return the result. Useful for checking package attributes or config values.
        :param expression: The Nix expression to evaluate (e.g., "pkgs.firefox.meta.description", "builtins.currentSystem")
        :return: The evaluated result
        """
        if __event_emitter__:
            await __event_emitter__({
                "type": "status",
                "data": {"description": f"Evaluating expression...", "done": False}
            })

        try:
            result = subprocess.run(
                ["nix", "eval", "--impure", "--expr", f"with import <nixpkgs> {{}}; {expression}"],
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode == 0:
                output = result.stdout.strip()
            else:
                output = f"Evaluation error: {result.stderr}"

        except subprocess.TimeoutExpired:
            output = "Evaluation timed out."
        except Exception as e:
            output = f"Error: {str(e)}"

        if __event_emitter__:
            await __event_emitter__({
                "type": "status",
                "data": {"description": "Complete", "done": True}
            })

        return output
