// 
//  ViewContainer.vala
//  
//  Authors:
//       Mathijs Henquet <mathijs.henquet@gmail.com>
//       ammonkey <am.monkeyd@gmail.com>
// 
//  Copyright (c) 2010 Mathijs Henquet
// 
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 3 of the License, or
//  (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
// 
using Gtk;

namespace Marlin.View {
    public class ViewContainer : Gtk.HPaned {
        public Gtk.Widget? content_item;
        public Gtk.Label label;
        private Marlin.View.Window window;
        public GOF.Window.Slot? slot;
        public Marlin.Window.Columns? mwcol;
        Browser<string> browser;
        public int view_mode = 0;
        private ContextView contextbar;

        public signal void path_changed(File file);
        public signal void up();
        public signal void back();
        public signal void forward();

        public ViewContainer(Marlin.View.Window win, GLib.File location){
            window = win;
            browser = new Browser<string> ();
            slot = new GOF.Window.Slot(location, this);
            /*mwcol = new Marlin.Window.Columns(location, this);
              slot = mwcol.active_slot;*/
            //content_item = slot.get_view();
            //label = new Gtk.Label("test");
            label = new Gtk.Label(slot.directory.get_uri());
            label.set_ellipsize(Pango.EllipsizeMode.END);
            label.set_single_line_mode(true);
            label.set_alignment(0.0f, 0.5f);
            label.set_padding(0, 0);
            update_location_state(true);

            /* ContextView */
            contextbar = new ContextView(window);
            contextbar.set_size_request(150, -1);

            /* Devide for contextbar */
            this.show();
            this.pack2(contextbar, false, true);
            //sidebar_box.set_name("app-sidebar"); //TODO where is this for? and what should it be?

            path_changed.connect((myfile) => {
                                 change_view(view_mode, myfile);
                                 update_location_state(true);
                                 });
            up.connect(() => {
                       if (slot.directory.has_parent()) {
                       change_view(view_mode, slot.directory.get_parent());
                       update_location_state(true);
                       }
                       });
            back.connect(() => {
                         change_view(view_mode, File.new_for_commandline_arg(browser.go_back()));
                         update_location_state(false);
                         });
            forward.connect(() => {
                            change_view(view_mode, File.new_for_commandline_arg(browser.go_forward()));
                            update_location_state(false);
                            });

            
        }

        public Widget content{
            set{
                if (content_item != null)
                    remove(content_item);
                pack1(value, true, true);
                content_item = value;
                //content_item.show();
                ((Bin)value).get_child().grab_focus();
                show();
            }
            get{
                return content_item;
            }
        }

        public string tab_name{
            set{
                label.label = value;	
            }
        }

        public void change_view(int nview, GLib.File? location){
            if (location == null)
                location = slot.location;
            view_mode = nview;
            if (window.top_menu.view_switcher != null)
                window.top_menu.view_switcher.mode = (ViewMode) view_mode;
            slot.directory.cancel();
            switch (nview) {
            case ViewMode.MILLER:
                mwcol = new Marlin.Window.Columns(location, this);
                slot = mwcol.active_slot;
                contextbar.update(null);
                break;
            default:
                slot = new GOF.Window.Slot(location, this);
                break;
            }
        }

        public void reload(){
                change_view(view_mode, null);
        }

        public void update_location_state(bool save_history)
        {
            window.can_go_up = slot.directory.has_parent();
            tab_name = slot.directory.get_uri();
            if (window.top_menu.location_bar != null)
                window.top_menu.location_bar.path = slot.directory.get_uri();
            if (save_history)
                browser.record_uri(slot.directory.get_uri());
            window.can_go_back = browser.can_go_back();
            window.can_go_forward = browser.can_go_forward();
            if (window.top_menu.view_switcher != null)
                window.top_menu.view_switcher.mode = (ViewMode) view_mode;
        }

        public new Gtk.Widget get_window()
        {
                return ((Gtk.Widget) window);
        }
    }
}
